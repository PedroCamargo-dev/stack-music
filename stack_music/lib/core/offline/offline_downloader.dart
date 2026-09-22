import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../api/subsonic_client.dart';
import '../models/subsonic_models.dart';
import 'download_store.dart';

/// Gerencia downloads do Navidrome com fila persistente, concorrência limitada
/// e retomada por HTTP Range a partir de arquivos parciais em disco.
class OfflineDownloader extends ChangeNotifier {
  OfflineDownloader(
    this.client,
    this.store, {
    Dio? dio,
    bool Function()? mayDownload,
    String Function(SubsonicSong song)? downloadUrlFor,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(minutes: 30),
              sendTimeout: const Duration(seconds: 15),
            )),
        _mayDownload = mayDownload ?? (() => true),
        _downloadUrlFor =
            downloadUrlFor ?? ((song) => client.downloadUrl(song.id)) {
    store.addListener(notifyListeners);
  }

  static const int maxConcurrent = 3;
  static const int maxAttempts = 5;

  final SubsonicClient client;
  final DownloadStore store;
  final Dio _dio;
  final bool Function() _mayDownload;
  final String Function(SubsonicSong song) _downloadUrlFor;
  final Map<String, CancelToken> _activeTokens = {};
  final Map<String, double> _progress = {};
  final Map<String, SubsonicSong> _knownSongs = {};
  final Set<String> _discardPartial = {};

  bool _processing = false;
  bool _paused = false;

  Map<String, double> get progress => Map.unmodifiable(_progress);
  bool get isPaused => _paused;

  double progressForJob(DownloadJob job) {
    if (job.trackIds.isEmpty) return 0;
    final total = job.trackIds.fold<double>(0, (sum, trackId) {
      if (store.isDownloaded(trackId)) return sum + 1;
      return sum + (_progress[trackId] ?? 0);
    });
    return (total / job.trackIds.length).clamp(0, 1);
  }

  Future<void> enqueueTrack(SubsonicSong song) async {
    _knownSongs[song.id] = song;
    if (store.isDownloaded(song.id) || store.isDownloading(song.id)) return;

    await store.enqueueJob(DownloadJob(
      id: 'track-${song.id}',
      type: 'track',
      trackIds: [song.id],
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    unawaited(resumePending());
  }

  Future<void> enqueueAlbum(SubsonicAlbum album) async {
    final songs = await client.getSongsOfAlbum(album.id);
    if (songs.isEmpty) return;
    for (final song in songs) {
      _knownSongs[song.id] = song;
    }
    await _enqueueCollection(
      id: 'album-${album.id}',
      type: 'album',
      collectionId: album.id,
      songs: songs,
    );
  }

  Future<void> enqueuePlaylist(
    SubsonicPlaylist playlist, {
    List<SubsonicSong>? songs,
  }) async {
    final resolvedSongs = songs ?? await client.getPlaylistSongs(playlist.id);
    if (resolvedSongs.isEmpty) return;
    for (final song in resolvedSongs) {
      _knownSongs[song.id] = song;
    }
    await _enqueueCollection(
      id: 'playlist-${playlist.id}',
      type: 'playlist',
      collectionId: playlist.id,
      songs: resolvedSongs,
    );
  }

  Future<void> _enqueueCollection({
    required String id,
    required String type,
    required String collectionId,
    required List<SubsonicSong> songs,
  }) async {
    await store.enqueueJob(DownloadJob(
      id: id,
      type: type,
      collectionId: collectionId,
      trackIds: songs.map((song) => song.id).toList(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    unawaited(resumePending());
  }

  Future<void> cancelJob(String jobId) async {
    final job = store.jobs.where((candidate) => candidate.id == jobId).firstOrNull;
    if (job == null) return;

    for (final trackId in job.trackIds) {
      _discardPartial.add(trackId);
      _activeTokens[trackId]?.cancel('User cancelled');
      if (!_activeTokens.containsKey(trackId)) {
        await _deletePartial(trackId);
      }
      _progress.remove(trackId);
      store.setDownloading(trackId, false);
    }
    await store.removeJob(jobId);
    notifyListeners();
  }

  Future<void> pauseActive() async {
    _paused = true;
    for (final token in _activeTokens.values) {
      token.cancel('Downloads paused');
    }
    notifyListeners();
  }

  Future<void> resumePending() async {
    _paused = false;
    await _processQueue();
  }

  Future<void> removeDownload(String trackId) async {
    final entry = store.tracks.where((track) => track.trackId == trackId).firstOrNull;
    if (entry != null) {
      final file = File(entry.localPath);
      if (await file.exists()) await file.delete();
    }
    await store.removeTrack(trackId);
    notifyListeners();
  }

  Future<void> removeAllDownloads() async {
    final entries = List<DownloadedTrackEntry>.from(store.tracks);
    for (final entry in entries) {
      final file = File(entry.localPath);
      if (await file.exists()) await file.delete();
    }
    await store.clearTracks();
    notifyListeners();
  }

  String? localPathFor(String trackId) {
    final entry = store.tracks.where((track) => track.trackId == trackId).firstOrNull;
    if (entry == null || !File(entry.localPath).existsSync()) return null;
    return entry.localPath;
  }

  Future<void> _processQueue() async {
    if (_paused || _processing || !_mayDownload()) return;
    _processing = true;

    try {
      while (!_paused && _activeTokens.length < maxConcurrent) {
        final pendingJob = store.jobs.where((job) {
          return job.attempts < maxAttempts &&
              job.trackIds.any((trackId) =>
                  !store.isDownloaded(trackId) &&
                  !store.isDownloading(trackId));
        }).firstOrNull;
        if (pendingJob == null) break;

        final trackId = pendingJob.trackIds.firstWhere(
          (candidate) =>
              !store.isDownloaded(candidate) &&
              !store.isDownloading(candidate),
        );
        unawaited(_downloadTrack(trackId, pendingJob));
      }
    } finally {
      _processing = false;
    }
  }

  Future<SubsonicSong> _resolveSong(String trackId) async {
    try {
      final fresh = await client.getSong(trackId);
      _knownSongs[trackId] = fresh;
      return fresh;
    } catch (_) {
      final cached = _knownSongs[trackId];
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> _downloadTrack(String trackId, DownloadJob job) async {
    store.setDownloading(trackId, true);
    final cancelToken = CancelToken();
    _activeTokens[trackId] = cancelToken;
    String? partialPath;
    String? currentUrl;
    var completed = false;

    try {
      final song = await _resolveSong(trackId);
      final downloadDir = await _downloadDirectory();
      currentUrl = _downloadUrlFor(song);

      final saved = store.resumables
          .where((entry) => entry.trackId == trackId)
          .firstOrNull;
      final savedFile = saved == null ? null : File(saved.fileUri);
      final partialFile = savedFile != null && await savedFile.exists()
          ? savedFile
          : File('${downloadDir.path}/${_safeFileName(trackId)}.part');
      partialPath = partialFile.path;
      final startBytes = await partialFile.exists() ? await partialFile.length() : 0;

      await store.upsertResumable(PersistedResumable(
        trackId: trackId,
        url: currentUrl,
        fileUri: partialPath,
        receivedBytes: startBytes,
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ));

      final headers = <String, dynamic>{
        HttpHeaders.acceptEncodingHeader: 'identity',
        if (startBytes > 0) HttpHeaders.rangeHeader: 'bytes=$startBytes-',
      };
      final response = await _dio.get<ResponseBody>(
        currentUrl,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
          validateStatus: (status) =>
              status == HttpStatus.ok || status == HttpStatus.partialContent,
        ),
        cancelToken: cancelToken,
      );
      final body = response.data;
      if (body == null) throw const HttpException('Resposta de download vazia');

      final append = startBytes > 0 && response.statusCode == HttpStatus.partialContent;
      var written = append ? startBytes : 0;
      final expectedBytes = _expectedTotalBytes(
        response.headers,
        startBytes: append ? startBytes : 0,
      );
      final sink = partialFile.openWrite(
        mode: append ? FileMode.append : FileMode.write,
      );
      try {
        await for (final chunk in body.stream) {
          sink.add(chunk);
          written += chunk.length;
          if (expectedBytes > 0) {
            _progress[trackId] = (written / expectedBytes).clamp(0, 1);
            notifyListeners();
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (expectedBytes > 0 && written < expectedBytes) {
        throw HttpException(
          'Download incompleto: $written de $expectedBytes bytes',
        );
      }

      final extension = _extensionFor(
        song,
        response.headers.value(Headers.contentTypeHeader),
      );
      final finalFile = File(
        '${downloadDir.path}/${_safeFileName(trackId)}.$extension',
      );
      if (await finalFile.exists()) await finalFile.delete();
      await partialFile.rename(finalFile.path);
      final stat = await finalFile.stat();

      await store.addTrack(DownloadedTrackEntry(
        trackId: trackId,
        localPath: finalFile.path,
        fileSize: stat.size,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
        albumId: song.albumId,
        artistId: song.artistId,
        title: song.title,
        artist: song.artist,
        album: song.album,
        suffix: extension,
        coverArtId: song.coverArt,
      ));
      await store.removeResumable(trackId);
      _progress.remove(trackId);
      completed = true;

      if (job.trackIds.every(store.isDownloaded)) {
        await store.removeJob(job.id);
      }
    } on DioException catch (error) {
      if (error.type != DioExceptionType.cancel) {
        await _recordFailure(job, error);
      }
    } catch (error) {
      await _recordFailure(job, error);
    } finally {
      _activeTokens.remove(trackId);
      store.setDownloading(trackId, false);

      final discard = _discardPartial.remove(trackId);
      if (discard) {
        await _deletePartial(trackId, path: partialPath);
      } else if (!completed && partialPath != null) {
        final partial = File(partialPath);
        if (await partial.exists()) {
          final bytes = await partial.length();
          if (bytes > 0) {
            await store.upsertResumable(PersistedResumable(
              trackId: trackId,
              url: currentUrl ?? '',
              fileUri: partialPath,
              receivedBytes: bytes,
              savedAt: DateTime.now().millisecondsSinceEpoch,
            ));
          }
        }
      }

      notifyListeners();
      if (!_paused) {
        unawaited(Future<void>.microtask(_processQueue));
      }
    }
  }

  Future<void> _recordFailure(DownloadJob job, Object error) async {
    debugPrint('[OfflineDownloader] ${job.id} falhou: $error');
    final attempts = job.attempts + 1;
    if (attempts >= maxAttempts) {
      await store.removeJob(job.id);
    } else {
      await store.updateJobAttempts(job.id, attempts);
    }
  }

  Future<Directory> _downloadDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/StackMusic/Downloads');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<void> _deletePartial(String trackId, {String? path}) async {
    final saved = store.resumables
        .where((entry) => entry.trackId == trackId)
        .firstOrNull;
    final partialPath = path ?? saved?.fileUri;
    if (partialPath != null) {
      final file = File(partialPath);
      if (await file.exists()) await file.delete();
    }
    await store.removeResumable(trackId);
  }

  int _expectedTotalBytes(Headers headers, {required int startBytes}) {
    final contentRange = headers.value(HttpHeaders.contentRangeHeader);
    if (contentRange != null) {
      final total = int.tryParse(contentRange.split('/').last);
      if (total != null) return total;
    }
    final contentLength = int.tryParse(
      headers.value(Headers.contentLengthHeader) ?? '',
    );
    return contentLength == null ? 0 : startBytes + contentLength;
  }

  String _extensionFor(SubsonicSong song, String? responseContentType) {
    final suffix = song.suffix?.trim().toLowerCase();
    if (suffix != null && RegExp(r'^[a-z0-9]{2,5}$').hasMatch(suffix)) {
      return suffix;
    }
    final contentType = (responseContentType ?? song.contentType ?? '')
        .split(';')
        .first
        .trim()
        .toLowerCase();
    return switch (contentType) {
      'audio/flac' => 'flac',
      'audio/mp4' || 'audio/x-m4a' => 'm4a',
      'audio/ogg' || 'application/ogg' => 'ogg',
      'audio/opus' => 'opus',
      'audio/wav' || 'audio/x-wav' => 'wav',
      'audio/aac' => 'aac',
      _ => 'mp3',
    };
  }

  String _safeFileName(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  @override
  void dispose() {
    _paused = true;
    store.removeListener(notifyListeners);
    for (final token in _activeTokens.values) {
      token.cancel('Downloader disposed');
    }
    _activeTokens.clear();
    super.dispose();
  }
}
