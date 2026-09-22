import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_music/core/api/subsonic_client.dart';
import 'package:stack_music/core/models/subsonic_models.dart';
import 'package:stack_music/core/offline/download_store.dart';
import 'package:stack_music/core/offline/offline_downloader.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

class _DownloadClient extends SubsonicClient {
  _DownloadClient({required this.url, required this.song})
      : super(
          baseUrl: 'https://music.example.test',
          username: 'alice',
          password: 'test-only',
        );

  final String url;
  final SubsonicSong song;

  @override
  String downloadUrl(String songId) => url;

  @override
  Future<SubsonicSong> getSong(String id) async => song;
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condição não atingida antes do timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('stack-music-download-test-');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('remove todos os downloads e arquivos locais', () async {
    final first = File('${tempDir.path}/first.mp3');
    final second = File('${tempDir.path}/second.flac');
    await first.writeAsBytes([1]);
    await second.writeAsBytes([2]);
    final store = DownloadStore();
    await store.load();
    await store.addTrack(DownloadedTrackEntry(
      trackId: 'first',
      localPath: first.path,
      fileSize: 1,
      downloadedAt: 1,
      albumId: '',
      artistId: '',
      title: 'First',
    ));
    await store.addTrack(DownloadedTrackEntry(
      trackId: 'second',
      localPath: second.path,
      fileSize: 1,
      downloadedAt: 2,
      albumId: '',
      artistId: '',
      title: 'Second',
    ));
    final song = SubsonicSong(id: 'first', title: 'First', artist: 'Artist');
    final dynamic downloader = OfflineDownloader(
      _DownloadClient(url: 'https://example.test/file', song: song),
      store,
    );

    await downloader.removeAllDownloads();

    expect(store.tracks, isEmpty);
    expect(await first.exists(), isFalse);
    expect(await second.exists(), isFalse);
  });

  test('download grava bytes em disco com formato e metadados da faixa', () async {
    final bytes = List<int>.generate(128, (index) => index);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('audio', 'flac')
        ..contentLength = bytes.length
        ..add(bytes);
      await request.response.close();
    });

    final song = SubsonicSong(
      id: 'song-flac',
      title: 'Lossless Track',
      artist: 'Artist',
      artistId: 'artist-1',
      album: 'Album',
      albumId: 'album-1',
      suffix: 'flac',
      contentType: 'audio/flac',
      coverArt: 'cover-1',
    );
    final store = DownloadStore();
    await store.load();
    final downloader = OfflineDownloader(
      _DownloadClient(
        url: 'http://${server.address.host}:${server.port}/song',
        song: song,
      ),
      store,
    );

    await downloader.enqueueTrack(song);
    await _waitUntil(() => store.isDownloaded(song.id));

    final dynamic entry = store.tracks.single;
    expect(entry.title, song.title);
    expect(entry.artist, song.artist);
    expect(entry.album, song.album);
    expect(entry.albumId, song.albumId);
    expect(entry.artistId, song.artistId);
    expect(entry.coverArtId, song.coverArt);
    expect(entry.localPath, endsWith('.flac'));
    expect(await File(entry.localPath).readAsBytes(), bytes);
  });

  test('usa o resolvedor de URL configurado para o download', () async {
    String? requestedPath;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      requestedPath = request.uri.path;
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('audio', 'mpeg')
        ..contentLength = 3
        ..add([1, 2, 3]);
      await request.response.close();
    });
    final song = SubsonicSong(
      id: 'song-quality',
      title: 'Quality Track',
      artist: 'Artist',
      suffix: 'mp3',
    );
    final client = _DownloadClient(
      url: 'http://${server.address.host}:${server.port}/original',
      song: song,
    );
    final store = DownloadStore();
    await store.load();
    final downloader = OfflineDownloader(
      client,
      store,
      downloadUrlFor: (_) =>
          'http://${server.address.host}:${server.port}/transcoded',
    );

    await downloader.enqueueTrack(song);
    await _waitUntil(() => store.isDownloaded(song.id));

    expect(requestedPath, '/transcoded');
  });

  test('fila permanece pendente offline e drena quando a conexão volta', () async {
    final bytes = List<int>.generate(64, (index) => index);
    var requests = 0;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      requests++;
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('audio', 'mpeg')
        ..contentLength = bytes.length
        ..add(bytes);
      await request.response.close();
    });

    var online = false;
    final song = SubsonicSong(
      id: 'song-offline-queue',
      title: 'Queued Track',
      artist: 'Artist',
      suffix: 'mp3',
    );
    final store = DownloadStore();
    await store.load();
    final downloader = OfflineDownloader(
      _DownloadClient(
        url: 'http://${server.address.host}:${server.port}/song',
        song: song,
      ),
      store,
      mayDownload: () => online,
    );

    await downloader.enqueueTrack(song);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(requests, 0);
    expect(store.jobs, hasLength(1));
    expect(store.jobs.single.attempts, 0);

    online = true;
    await downloader.resumePending();
    await _waitUntil(() => store.isDownloaded(song.id));

    expect(requests, 1);
    expect(store.jobs, isEmpty);
  });

  test('download retomado usa Range e preserva os bytes já gravados', () async {
    final bytes = List<int>.generate(256, (index) => index % 251);
    String? receivedRange;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      receivedRange = request.headers.value(HttpHeaders.rangeHeader);
      final start = receivedRange == null
          ? 0
          : int.parse(receivedRange!.replaceFirst('bytes=', '').split('-').first);
      final remaining = bytes.sublist(start);
      request.response
        ..statusCode = start > 0 ? HttpStatus.partialContent : HttpStatus.ok
        ..headers.contentType = ContentType('audio', 'mpeg')
        ..headers.set(HttpHeaders.contentRangeHeader,
            'bytes $start-${bytes.length - 1}/${bytes.length}')
        ..contentLength = remaining.length
        ..add(remaining);
      await request.response.close();
    });

    final song = SubsonicSong(
      id: 'song-resume',
      title: 'Resume Track',
      artist: 'Artist',
      suffix: 'mp3',
    );
    final partial = File('${tempDir.path}/song-resume.part');
    await partial.writeAsBytes(bytes.sublist(0, 80));
    final store = DownloadStore();
    await store.load();
    await store.upsertResumable(PersistedResumable(
      trackId: song.id,
      url: 'previous-url',
      fileUri: partial.path,
      receivedBytes: 80,
      savedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    final downloader = OfflineDownloader(
      _DownloadClient(
        url: 'http://${server.address.host}:${server.port}/song',
        song: song,
      ),
      store,
    );

    await downloader.enqueueTrack(song);
    await _waitUntil(() => store.isDownloaded(song.id));

    expect(receivedRange, 'bytes=80-');
    expect(await File(store.tracks.single.localPath).readAsBytes(), bytes);
    expect(store.resumables, isEmpty);
  });
}
