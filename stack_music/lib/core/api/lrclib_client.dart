import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente para a API pública LRCLib (https://lrclib.net/docs).
/// Retorna letras sincronizadas (LRC) ou texto puro como fallback.
class LrcLibClient {
  static const _baseUrl = 'https://lrclib.net/api';
  final http.Client _http;

  LrcLibClient({http.Client? client}) : _http = client ?? http.Client();

  /// Busca letra por artista e título. Retorna null se não encontrar.
  Future<LrcLyrics?> getLyrics(String artist, String title) async {
    try {
      final uri = Uri.parse('$_baseUrl/get')
          .replace(queryParameters: {'artist_name': artist, 'track_name': title});
      final response = await _http.get(uri);
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return LrcLyrics.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  void dispose() => _http.close();
}

class LrcLyrics {
  final String artist;
  final String title;
  final String? syncedLyrics; // formato LRC com timestamps [mm:ss.xx]
  final String? plainLyrics;

  LrcLyrics({
    required this.artist,
    required this.title,
    this.syncedLyrics,
    this.plainLyrics,
  });

  factory LrcLyrics.fromJson(Map<String, dynamic> j) => LrcLyrics(
        artist: j['artistName'] ?? '',
        title: j['trackName'] ?? '',
        syncedLyrics: j['syncedLyrics'] as String?,
        plainLyrics: j['plainLyrics'] as String?,
      );

  /// Retorna a melhor versão disponível: sincronizada > texto puro.
  String? get bestText => syncedLyrics ?? plainLyrics;

  bool get hasSynced => syncedLyrics != null && syncedLyrics!.isNotEmpty;
}