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

  bool get isConfigured => subsonic != null;

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    downloadApiUrl = sp.getString('download_api_url') ?? 'http://localhost:3333';

    final saved = await SubsonicClient.loadSaved();
    if (saved != null) {
      await connect(saved.baseUrl, saved.username, saved.password,
          persist: false);
    }
    if (subsonic == null) {
      downloadApi = DownloadApiClient(baseUrl: downloadApiUrl);
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

  /// Conecta ao Navidrome e valida com ping. Persiste em caso de sucesso.
  Future<void> connect(String url, String user, String pass,
      {bool persist = true}) async {
    final client = SubsonicClient(baseUrl: url, username: user, password: pass);
    await client.ping(); // lança exceção se falhar
    if (persist) await client.save();
    subsonic = client;
    player = PlayerHandler(client);
    downloadApi ??= DownloadApiClient(baseUrl: downloadApiUrl);
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