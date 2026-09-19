import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

/// Resultado de busca da music-download-api (YouTube + Spotify).
class SearchItem {
  final String title;
  final String artist; // canal do YouTube ou artista Spotify
  final String thumbnail;
  final String url; // link canônico para download
  final String platform; // youtube | spotify
  final String type; // track | video | playlist | album | artist
  final String? duration;

  SearchItem({
    required this.title,
    this.artist = '',
    this.thumbnail = '',
    required this.url,
    required this.platform,
    required this.type,
    this.duration,
  });

  bool get isCollection => type == 'playlist' || type == 'album' || type == 'artist';
}

class DownloadSearchResponse {
  final List<SearchItem> items;
  final int totalSpotifyTracks;
  final bool hasNext;

  DownloadSearchResponse({required this.items, this.totalSpotifyTracks = 0, this.hasNext = false});
}

/// Cliente da API própria (Go/Gin, porta 3333).
/// Endpoints: GET /search, POST /process-urls, POST /download (chunked stream).
class DownloadApiClient {
  final Dio dio;
  final String baseUrl;

  DownloadApiClient({required this.baseUrl, Dio? dio})
      : dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(minutes: 10),
          responseType: ResponseType.stream,
        ));

  Uri _uri(String path, [Map<String, String>? q]) =>
      Uri.parse((baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl) + path)
          .replace(queryParameters: q ?? {});

  /// Busca unificada YouTube + Spotify.
  Future<DownloadSearchResponse> search(String query, {int limit = 10}) async {
    final resp = await Dio().getUri(_uri('/search', {
      'query': query,
      'limit': '$limit',
      'maxResults': '$limit',
    }));
    final data = resp.data as Map<String, dynamic>;
    final items = <SearchItem>[];

    // YouTube
    final yt = data['youtube'] as Map<String, dynamic>?;
    for (final video in (yt?['videos'] as List? ?? [])) {
      final v = video as Map<String, dynamic>;
      final snippet = v['snippet'] as Map<String, dynamic>? ?? {};
      items.add(SearchItem(
        title: snippet['title'] ?? '',
        artist: snippet['channelTitle'] ?? '',
        thumbnail: ((snippet['thumbnails'] as Map<String, dynamic>?)?['medium']
            as Map<String, dynamic>?)?['url'] ?? '',
        url: 'https://www.youtube.com/watch?v=${v['id']?['videoId'] ?? v['id']}',
        platform: 'youtube',
        type: 'video',
      ));
    }
    for (final pl in (yt?['playlists'] as List? ?? [])) {
      final p = pl as Map<String, dynamic>;
      final snippet = p['snippet'] as Map<String, dynamic>? ?? {};
      items.add(SearchItem(
        title: snippet['title'] ?? '',
        artist: snippet['channelTitle'] ?? '',
        thumbnail: ((snippet['thumbnails'] as Map<String, dynamic>?)?['medium']
            as Map<String, dynamic>?)?['url'] ?? '',
        url: 'https://www.youtube.com/playlist?list=${p['id']?['playlistId'] ?? p['id']}',
        platform: 'youtube',
        type: 'playlist',
      ));
    }

    // Spotify
    final sp = data['spotify'] as Map<String, dynamic>?;
    final tracks = (sp?['tracks'] as List? ?? []);
    for (final t in tracks) {
      final m = t as Map<String, dynamic>;
      final artists = (m['artists'] as List? ?? []);
      final album = (m['album'] as Map<String, dynamic>? ?? {});
      final images = (album['images'] as List? ?? []);
      final durMs = (m['duration_ms'] as num?)?.toInt() ?? 0;
      items.add(SearchItem(
        title: m['name'] ?? '',
        artist: artists.isNotEmpty ? (artists[0] as Map<String, dynamic>)['name'] ?? '' : '',
        thumbnail: images.isNotEmpty ? (images[0] as Map<String, dynamic>)['url'] ?? '' : '',
        url: m['external_urls']?['spotify'] ?? '',
        platform: 'spotify',
        type: 'track',
        duration: durMs > 0 ? '${durMs ~/ 60000}:${((durMs % 60000) ~/ 1000).toString().padLeft(2, '0')}' : null,
      ));
    }
    for (final e in ['albums', 'artists', 'playlists']) {
      for (final raw in (sp?[e] as List? ?? [])) {
        final m = raw as Map<String, dynamic>;
        final images = (m['images'] as List? ?? []);
        items.add(SearchItem(
          title: m['name'] ?? '',
          thumbnail: images.isNotEmpty ? (images[0] as Map<String, dynamic>)['url'] ?? '' : '',
          url: m['external_urls']?['spotify'] ?? '',
          platform: 'spotify',
          type: e == 'albums' ? 'album' : e.substring(0, e.length - 1),
        ));
      }
    }

    return DownloadSearchResponse(
      items: items,
      totalSpotifyTracks: (sp?['pagination'] as Map<String, dynamic>?)?['total_tracks'] ?? 0,
      hasNext: (sp?['pagination'] as Map<String, dynamic>?)?['has_next_track'] == true,
    );
  }

  /// POST /download — inicia downloads no servidor e transmite o progresso
  /// linha a linha (chunked text). Retorna stream de mensagens de progresso.
  Stream<String> download(List<String> urls) async* {
    final resp = await dio.postUri(
      _uri('/download'),
      data: {'urls': urls},
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final stream = resp.data.stream as Stream<List<int>>;
    final lines = stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (line.trim().isNotEmpty) yield line;
    }
  }
}