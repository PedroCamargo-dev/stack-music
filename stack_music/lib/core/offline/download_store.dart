import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entrada persistente de uma faixa baixada com sucesso.
class DownloadedTrackEntry {
  final String trackId;
  final String localPath;
  final int fileSize;
  final int downloadedAt;
  final String albumId;
  final String artistId;
  final String title;
  final String artist;
  final String album;
  final String? suffix;
  final String? coverArtId;

  const DownloadedTrackEntry({
    required this.trackId,
    required this.localPath,
    required this.fileSize,
    required this.downloadedAt,
    required this.albumId,
    required this.artistId,
    required this.title,
    this.artist = '',
    this.album = '',
    this.suffix,
    this.coverArtId,
  });

  Map<String, dynamic> toJson() => {
        'trackId': trackId,
        'localPath': localPath,
        'fileSize': fileSize,
        'downloadedAt': downloadedAt,
        'albumId': albumId,
        'artistId': artistId,
        'title': title,
        'artist': artist,
        'album': album,
        'suffix': suffix,
        'coverArtId': coverArtId,
      };

  factory DownloadedTrackEntry.fromJson(Map<String, dynamic> j) =>
      DownloadedTrackEntry(
        trackId: j['trackId'] as String,
        localPath: j['localPath'] as String,
        fileSize: j['fileSize'] as int,
        downloadedAt: j['downloadedAt'] as int,
        albumId: j['albumId'] as String? ?? '',
        artistId: j['artistId'] as String? ?? '',
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? '',
        album: j['album'] as String? ?? '',
        suffix: j['suffix'] as String?,
        coverArtId: j['coverArtId'] as String?,
      );
}

/// Estado resumível de um download pausado/interrrompido.
class PersistedResumable {
  final String trackId;
  final String url;
  final String fileUri;
  final int? receivedBytes;
  final int savedAt;

  const PersistedResumable({
    required this.trackId,
    required this.url,
    required this.fileUri,
    this.receivedBytes,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'trackId': trackId,
        'url': url,
        'fileUri': fileUri,
        'receivedBytes': receivedBytes,
        'savedAt': savedAt,
      };

  factory PersistedResumable.fromJson(Map<String, dynamic> j) =>
      PersistedResumable(
        trackId: j['trackId'] as String,
        url: j['url'] as String,
        fileUri: j['fileUri'] as String,
        receivedBytes: j['receivedBytes'] as int?,
        savedAt: j['savedAt'] as int,
      );
}

/// Job de download persistente (faixa, álbum ou playlist).
class DownloadJob {
  final String id;
  final String type; // 'track', 'album', 'playlist'
  final String? collectionId;
  final List<String> trackIds;
  final int createdAt;
  final int updatedAt;
  final int attempts;

  const DownloadJob({
    required this.id,
    required this.type,
    this.collectionId,
    required this.trackIds,
    required this.createdAt,
    required this.updatedAt,
    this.attempts = 0,
  });

  DownloadJob copyWith({int? attempts, int? updatedAt}) => DownloadJob(
        id: id,
        type: type,
        collectionId: collectionId,
        trackIds: trackIds,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        attempts: attempts ?? this.attempts,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'collectionId': collectionId,
        'trackIds': trackIds,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'attempts': attempts,
      };

  factory DownloadJob.fromJson(Map<String, dynamic> j) => DownloadJob(
        id: j['id'] as String,
        type: j['type'] as String,
        collectionId: j['collectionId'] as String?,
        trackIds: (j['trackIds'] as List).cast<String>(),
        createdAt: j['createdAt'] as int,
        updatedAt: j['updatedAt'] as int,
        attempts: (j['attempts'] as int?) ?? 0,
      );
}

/// Store persistente para downloads: faixas baixadas, jobs pendentes e
/// estado resumível. Usa SharedPreferences como backend simples e confiável.
class DownloadStore extends ChangeNotifier {
  static const _keyTracks = 'offline_tracks';
  static const _keyJobs = 'offline_jobs';
  static const _keyResumables = 'offline_resumables';

  List<DownloadedTrackEntry> _tracks = [];
  List<DownloadJob> _jobs = [];
  List<PersistedResumable> _resumables = [];
  final Set<String> _downloading = {};

  List<DownloadedTrackEntry> get tracks => List.unmodifiable(_tracks);
  List<DownloadJob> get jobs => List.unmodifiable(_jobs);
  List<PersistedResumable> get resumables => List.unmodifiable(_resumables);
  bool isDownloading(String trackId) => _downloading.contains(trackId);
  bool isDownloaded(String trackId) =>
      _tracks.any((t) => t.trackId == trackId);

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final tracksRaw = sp.getString(_keyTracks);
    final jobsRaw = sp.getString(_keyJobs);
    final resumablesRaw = sp.getString(_keyResumables);

    if (tracksRaw != null) {
      try {
        final decoded = jsonDecode(tracksRaw);
        if (decoded is List) {
          _tracks = decoded
              .whereType<Map>()
              .map((e) => DownloadedTrackEntry.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList();
        }
      } on FormatException {
        _tracks = [];
      }
    }
    if (jobsRaw != null) {
      try {
        final decoded = jsonDecode(jobsRaw);
        if (decoded is List) {
          _jobs = decoded
              .whereType<Map>()
              .map((e) => DownloadJob.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } on FormatException {
        _jobs = [];
      }
    }
    if (resumablesRaw != null) {
      try {
        final decoded = jsonDecode(resumablesRaw);
        if (decoded is List) {
          _resumables = decoded
              .whereType<Map>()
              .map((e) => PersistedResumable.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList();
        }
      } on FormatException {
        _resumables = [];
      }
    }
    notifyListeners();
  }

  Future<void> _saveTracks() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _keyTracks, jsonEncode(_tracks.map((t) => t.toJson()).toList()));
  }

  Future<void> _saveJobs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
        _keyJobs, jsonEncode(_jobs.map((j) => j.toJson()).toList()));
  }

  Future<void> _saveResumables() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_keyResumables,
        jsonEncode(_resumables.map((r) => r.toJson()).toList()));
  }

  void setDownloading(String trackId, bool value) {
    if (value) {
      _downloading.add(trackId);
    } else {
      _downloading.remove(trackId);
    }
    notifyListeners();
  }

  Future<void> addTrack(DownloadedTrackEntry entry) async {
    _tracks = [
      ..._tracks.where((t) => t.trackId != entry.trackId),
      entry,
    ];
    await _saveTracks();
    notifyListeners();
  }

  Future<void> removeTrack(String trackId) async {
    _tracks = _tracks.where((t) => t.trackId != trackId).toList();
    await _saveTracks();
    notifyListeners();
  }

  Future<void> clearTracks() async {
    _tracks = [];
    await _saveTracks();
    notifyListeners();
  }

  Future<void> enqueueJob(DownloadJob job) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final previous = _jobs.where((candidate) => candidate.id == job.id).firstOrNull;
    final merged = DownloadJob(
      id: job.id,
      type: job.type,
      collectionId: job.collectionId,
      trackIds: job.trackIds,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
      attempts: previous?.attempts ?? job.attempts,
    );
    _jobs = [
      ..._jobs.where((candidate) => candidate.id != job.id),
      merged,
    ];
    await _saveJobs();
    notifyListeners();
  }

  Future<void> removeJob(String jobId) async {
    _jobs = _jobs.where((j) => j.id != jobId).toList();
    await _saveJobs();
    notifyListeners();
  }

  Future<void> updateJobAttempts(String jobId, int attempts) async {
    _jobs = _jobs.map((j) {
      if (j.id == jobId) return j.copyWith(attempts: attempts, updatedAt: DateTime.now().millisecondsSinceEpoch);
      return j;
    }).toList();
    await _saveJobs();
    notifyListeners();
  }

  Future<void> upsertResumable(PersistedResumable r) async {
    _resumables = [
      ..._resumables.where((x) => x.trackId != r.trackId),
      r,
    ];
    await _saveResumables();
    notifyListeners();
  }

  Future<void> removeResumable(String trackId) async {
    _resumables = _resumables.where((r) => r.trackId != trackId).toList();
    await _saveResumables();
    notifyListeners();
  }

  /// Tamanho total ocupado por downloads (bytes).
  int get totalDownloadedBytes =>
      _tracks.fold<int>(0, (sum, t) => sum + t.fileSize);

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB'];
    double value = bytes / 1024;
    int unitIdx = 0;
    while (value >= 1024 && unitIdx < units.length - 1) {
      value /= 1024;
      unitIdx++;
    }
    return '${value.toStringAsFixed(value >= 100 ? 0 : value >= 10 ? 1 : 2)} ${units[unitIdx]}';
  }
}