import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/download_api_client.dart';
import 'api/subsonic_client.dart';
import 'player/player_handler.dart';

/// Estado global: conexões (Subsonic + download API) e player.
class AppState extends ChangeNotifier {
  SubsonicClient? subsonic;
  DownloadApiClient? downloadApi;
  PlayerHandler? player;

  /// URL da API de download (configurável nas settings).
  String downloadApiUrl = '';

  bool _ready = false;
  bool get ready => _ready;
  bool get isConfigured => subsonic != null;

  Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      downloadApiUrl = sp.getString('download_api_url') ?? 'http://localhost:3333';
      downloadApi = DownloadApiClient(baseUrl: downloadApiUrl);

      final saved = await SubsonicClient.loadSaved();
      if (saved != null) {
        try {
          await connect(saved.baseUrl, saved.username, saved.password,
              persist: false);
        } catch (_) {
          // credencial salva inválida/servidor offline: limpa e pede login
          subsonic = null;
          player = null;
        }
      }
    } catch (e) {
      debugPrint('AppState.init falhou, mostrando login: $e');
      subsonic = null;
      player = null;
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> setDownloadApiUrl(String url) async {
    downloadApiUrl = url;
    downloadApi = DownloadApiClient(baseUrl: url);
    final sp = await SharedPreferences.getInstance();
    await sp.setString('download_api_url', url);
    notifyListeners();
  }

  /// Conecta ao Navidrome, valida com ping e inicializa o audio_service
  /// (necessário para o player funcionar com notificação/background).
  Future<void> connect(String url, String user, String pass,
      {bool persist = true}) async {
    final client = SubsonicClient(baseUrl: url, username: user, password: pass);
    await client.ping(); // lança exceção se falhar
    if (persist) await client.save();
    subsonic = client;
 // audio_service pode falhar em alguns dispositivos (MIUI/foreground) ou se
 // ja foi inicializado; o login nao deve quebrar por isso.
 try {
 player ??= await AudioService.init(
 builder: () => PlayerHandler(client),
 config: const AudioServiceConfig(
 androidNotificationChannelId: 'com.pedrocamargo.stack_music.playback',
 androidNotificationChannelName: 'Stack Music',
 androidNotificationOngoing: true,
 androidStopForegroundOnPause: true,
 ),
 );
 } catch (e) {
 debugPrint('AudioService.init falhou, usando player local: $e');
 player ??= PlayerHandler(client);
 }
 notifyListeners();
  }

  Future<void> disconnect() async {
    await player?.stop();
    await SubsonicClient.clearSaved();
    subsonic = null;
    player = null;
    notifyListeners();
  }
}