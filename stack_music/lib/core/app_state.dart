import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/download_api_client.dart';
import 'api/subsonic_client.dart';
import 'offline/download_quality.dart';
import 'offline/download_store.dart';
import 'offline/offline_downloader.dart';
import 'player/player_handler.dart';

/// Estado global: conexão Navidrome, API externa, player e downloads offline.
class AppState extends ChangeNotifier {
  SubsonicClient? subsonic;
  DownloadApiClient? downloadApi;
  PlayerHandler? player;
  DownloadStore? downloadStore;
  OfflineDownloader? downloader;

  String downloadApiUrl = '';
  DownloadQuality downloadQuality = DownloadQuality.original;

  bool _ready = false;
  bool _serverReachable = false;

  bool get ready => _ready;
  bool get isConfigured => subsonic != null;
  bool get serverReachable => _serverReachable;
  bool get isOffline => isConfigured && !_serverReachable;

  Future<void> init() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      downloadApiUrl =
          preferences.getString('download_api_url') ?? 'http://localhost:3333';
      downloadQuality = DownloadQuality.fromStorage(
        preferences.getString('download_quality'),
      );
      downloadApi = DownloadApiClient(baseUrl: downloadApiUrl);

      downloadStore = DownloadStore();
      await downloadStore!.load();

      final saved = await SubsonicClient.loadSaved();
      if (saved != null) {
        subsonic = saved;
        try {
          await saved.ping();
          _serverReachable = true;
        } catch (error) {
          _serverReachable = false;
          debugPrint('Navidrome indisponível; iniciando em modo offline: $error');
        }
        await _initializeServices(saved);
        if (_serverReachable) {
          unawaited(downloader?.resumePending());
        }
      }
    } catch (error) {
      debugPrint('AppState.init falhou, mostrando login: $error');
      subsonic = null;
      player = null;
      downloader?.dispose();
      downloader = null;
      _serverReachable = false;
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> setDownloadApiUrl(String url) async {
    downloadApiUrl = url;
    downloadApi = DownloadApiClient(baseUrl: url);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('download_api_url', url);
    notifyListeners();
  }

  Future<void> setDownloadQuality(DownloadQuality quality) async {
    downloadQuality = quality;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('download_quality', quality.name);
    notifyListeners();
  }

  /// Conecta manualmente ao Navidrome. O login só é aceito após ping válido.
  Future<void> connect(
    String url,
    String user,
    String pass, {
    bool persist = true,
  }) async {
    final client = SubsonicClient(
      baseUrl: url,
      username: user,
      password: pass,
    );
    await client.ping();
    if (persist) await client.save();

    subsonic = client;
    _serverReachable = true;
    await _initializeServices(client);
    unawaited(downloader?.resumePending());
    notifyListeners();
  }

  Future<void> _initializeServices(SubsonicClient client) async {
    downloadStore ??= DownloadStore();
    if (downloadStore!.tracks.isEmpty &&
        downloadStore!.jobs.isEmpty &&
        downloadStore!.resumables.isEmpty) {
      await downloadStore!.load();
    }

    downloader?.dispose();
    downloader = OfflineDownloader(
      client,
      downloadStore!,
      mayDownload: () => _serverReachable,
      downloadUrlFor: (song) => downloadQuality.urlFor(client, song.id),
    );

    // audio_service pode falhar em alguns dispositivos/ROMs ou se já estiver
    // inicializado. O app mantém um player local como fallback.
    try {
      player ??= await AudioService.init(
        builder: () => PlayerHandler(
          client,
          localPathFor: downloader!.localPathFor,
        ),
        config: const AudioServiceConfig(
          androidNotificationChannelId:
              'com.pedrocamargo.stack_music.playback',
          androidNotificationChannelName: 'Stack Music',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
    } catch (error) {
      debugPrint('AudioService.init falhou, usando player local: $error');
      player ??= PlayerHandler(
        client,
        localPathFor: downloader!.localPathFor,
      );
    }
  }

  /// Revalida o servidor ao retomar o app e drena a fila quando a conexão volta.
  Future<bool> refreshServerReachability() async {
    final client = subsonic;
    if (client == null) return false;

    try {
      await client.ping();
      _serverReachable = true;
      unawaited(downloader?.resumePending());
    } catch (_) {
      _serverReachable = false;
      await downloader?.pauseActive();
    }
    notifyListeners();
    return _serverReachable;
  }

  Future<void> disconnect() async {
    await downloader?.pauseActive();
    downloader?.dispose();
    downloader = null;
    await player?.stop();
    await SubsonicClient.clearSaved();
    subsonic = null;
    player = null;
    _serverReachable = false;
    notifyListeners();
  }

  @override
  void dispose() {
    downloader?.dispose();
    super.dispose();
  }
}
