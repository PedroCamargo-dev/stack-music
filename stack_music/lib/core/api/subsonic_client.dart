import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/subsonic_models.dart';

/// Cliente da Subsonic API do Navidrome.
/// Autenticação: token = md5(password + salt), salt aleatório por request.
class SubsonicClient {
 final Dio dio;
 String baseUrl; // ex: https://music.example.com
 String username;
 String password;

 static const _apiVersion = '1.16.1';
 static const _clientName = 'stackmusic';

 SubsonicClient({Dio? dio, required this.baseUrl, required this.username, required this.password})
 : dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 30)));

 /// Persiste/restaura a conexão (tela de login manual).
 static Future<SubsonicClient?> loadSaved() async {
 final sp = await SharedPreferences.getInstance();
 final url = sp.getString('server_url');
 final user = sp.getString('server_user');
 final pass = sp.getString('server_pass');
 if (url == null || user == null || pass == null) return null;
 return SubsonicClient(baseUrl: url, username: user, password: pass);
 }

 Future<void> save() async {
 final sp = await SharedPreferences.getInstance();
 await sp.setString('server_url', baseUrl);
 await sp.setString('server_user', username);
 await sp.setString('server_pass', password);
 }

 static Future<void> clearSaved() async {
 final sp = await SharedPreferences.getInstance();
 await sp.remove('server_url');
 await sp.remove('server_user');
 await sp.remove('server_pass');
 }

 String _salt() {
 final rand = DateTime.now().microsecondsSinceEpoch.toString() +
 DateTime.now().millisecondsSinceEpoch.toString();
 return rand.padRight(6, 'x').substring(0, 12);
 }

 Map<String, dynamic> _authParams() {
 final salt = _salt();
 final token = crypto.md5.convert(utf8.encode(password + salt)).toString();
 return {'u': username, 't': token, 's': salt, 'v': _apiVersion, 'c': _clientName, 'f': 'json'};
 }

 Uri buildUri(String endpoint, [Map<String, dynamic>? params]) {
 final q = _authParams();
 params?.forEach((k, v) => q[k] = v.toString());
 final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
 return Uri.parse('$base/rest/$endpoint.view').replace(queryParameters: q.map((k, v) => MapEntry(k, v.toString())));
 }

 Future<Map<String, dynamic>> _get(String endpoint, [Map<String, dynamic>? params]) async {
 final resp = await dio.getUri(buildUri(endpoint, params));
 final body = resp.data as Map<String, dynamic>;
 final sub = body['subsonic-response'] as Map<String, dynamic>;
 if (sub['status'] != 'ok') {
 final err = sub['error'] as Map<String, dynamic>?;
 throw SubsonicException(err?['code'] ?? 0, err?['message'] ?? 'unknown error');
 }
 return sub;
 }

 // ---- System ----
 Future<bool> ping() async {
 await _get('ping');
 return true;
 }

 // ---- Browsing ----
 Future<List<SubsonicArtist>> getArtists() async {
 final sub = await _get('getArtists');
 final idx = (sub['artists'] as Map<String, dynamic>)['index'] as List? ?? [];
 return idx
 .expand((i) => (i['artist'] as List? ?? []) as Iterable<Map<String, dynamic>>)
 .map(SubsonicArtist.fromJson)
 .toList();
 }

 Future<SubsonicArtist> getArtist(String id) async {
 final sub = await _get('getArtist', {'id': id});
 return SubsonicArtist.fromJson((sub['artist'] as Map<String, dynamic>));
 }

 Future<List<SubsonicAlbum>> getAlbumsOfArtist(String artistId) async {
 final sub = await _get('getArtist', {'id': artistId});
 final albums = ((sub['artist'] as Map<String, dynamic>)['album'] as List? ?? []);
 return albums.cast<Map<String, dynamic>>().map(SubsonicAlbum.fromJson).toList();
 }

 Future<SubsonicAlbum> getAlbum(String id) async {
 final sub = await _get('getAlbum', {'id': id});
 return SubsonicAlbum.fromJson((sub['album'] as Map<String, dynamic>));
 }

 Future<List<SubsonicSong>> getSongsOfAlbum(String albumId) async {
 final album = await getAlbum(albumId);
 final sub = await _get('getAlbum', {'id': albumId});
 final songs = ((sub['album'] as Map<String, dynamic>)['song'] as List? ?? []);
 return songs.cast<Map<String, dynamic>>().map(SubsonicSong.fromJson).toList()
 ..forEach((s) {});
 }

 // ---- Album/Song lists ----
 Future<List<SubsonicAlbum>> getAlbumList({String type = 'newest', int size = 20}) async {
 final sub = await _get('getAlbumList2', {'type': type, 'size': size});
 final list = (sub['albumList2'] as Map<String, dynamic>)['album'] as List? ?? [];
 return list.cast<Map<String, dynamic>>().map(SubsonicAlbum.fromJson).toList();
 }

 Future<List<SubsonicSong>> getRandomSongs({int size = 20}) async {
 final sub = await _get('getRandomSongs', {'size': size});
 final list = (sub['randomSongs'] as Map<String, dynamic>)['song'] as List? ?? [];
 return list.cast<Map<String, dynamic>>().map(SubsonicSong.fromJson).toList();
 }

 Future<List<SubsonicSong>> getSongsByGenre(String genre, {int count = 20}) async {
 final sub = await _get('getSongsByGenre', {'genre': genre, 'count': count});
 final list = (sub['songsByGenre'] as Map<String, dynamic>)['song'] as List? ?? [];
 return list.cast<Map<String, dynamic>>().map(SubsonicSong.fromJson).toList();
 }

 Future<List<SubsonicSong>> getStarredSongs() async {
 final sub = await _get('getStarred2');
 final list = (sub['starred2'] as Map<String, dynamic>)['song'] as List? ?? [];
 return list.cast<Map<String, dynamic>>().map(SubsonicSong.fromJson).toList();
 }

 Future<List<SubsonicSong>> getTopSongs(String artistName, {int count = 20}) async {
 final sub = await _get('getTopSongs', {'artist': artistName, 'count': count});
 final list = (sub['topSongs'] as Map<String, dynamic>)['song'] as List? ?? [];
 return list.cast<Map<String, dynamic>>().map(SubsonicSong.fromJson).toList();
 }

 // ---- Genres ----
 Future<List<SubsonicGenre>> getGenres() async {
 final sub = await _get('getGenres');
 final list = sub['genres'] as List? ?? [];
 return list.cast<Map<String, dynamic>>().map(SubsonicGenre.fromJson).toList();
 }

 // ---- Search ----
 Future<SearchResult> search3(String query) async {
 final sub = await _get('search3', {
 'query': query, 'artistCount': 10, 'albumCount': 10, 'songCount': 20,
 });
 final sr = sub['searchResult3'] as Map<String, dynamic>;
 return SearchResult(
 artists: ((sr['artist'] as List? ?? [])).cast<Map<String, dynamic>>().map(SubsonicArtist.fromJson).toList(),
 albums: ((sr['album'] as List? ?? [])).cast<Map<String, dynamic>>().map(SubsonicAlbum.fromJson).toList(),
 songs: ((sr['song'] as List? ?? [])).cast<Map<String, dynamic>>().map(SubsonicSong.fromJson).toList(),
 );
 }

 // ---- Playlists ----
 Future<List<SubsonicPlaylist>> getPlaylists() async {
 final sub = await _get('getPlaylists');
 final list = (sub['playlists'] as Map<String, dynamic>)['playlist'] as List? ?? [];
 return list.cast<Map<String, dynamic>>().map(SubsonicPlaylist.fromJson).toList();
 }

 Future<List<SubsonicSong>> getPlaylistSongs(String playlistId) async {
 final sub = await _get('getPlaylist', {'id': playlistId});
 final list = (sub['playlist'] as Map<String, dynamic>)['entry'] as List? ?? [];
 return list.cast<Map<String, dynamic>>().map(SubsonicSong.fromJson).toList();
 }

 Future<SubsonicPlaylist> createPlaylist(String name, List<String> songIds) async {
 final sub = await _get('createPlaylist', {'name': name, 'songId': songIds.join(',')});
 final pl = (sub['playlist'] as Map<String, dynamic>);
 return SubsonicPlaylist.fromJson(pl);
 }

 Future<void> updatePlaylist(String id, {String? name, List<String>? songIdsToAdd}) async {
 final p = <String, dynamic>{'playlistId': id};
 if (name != null) p['name'] = name;
 if (songIdsToAdd != null) p['songIdToAdd'] = songIdsToAdd.join(',');
 await _get('updatePlaylist', p);
 }

 Future<void> deletePlaylist(String id) async => _get('deletePlaylist', {'id': id});

 // ---- Media retrieval ----
 String coverArtUrl(String? coverArtId, {int size = 600}) =>
 coverArtId == null ? '' : buildUri('getCoverArt', {'id': coverArtId, 'size': size}).toString();

 String streamUrl(String songId, {int maxBitRate = 320}) =>
 buildUri('stream', {'id': songId, 'maxBitRate': maxBitRate}).toString();

 String downloadUrl(String songId) => buildUri('download', {'id': songId}).toString();

 Future<Lyrics?> getLyrics(String artist, String title) async {
 final sub = await _get('getLyrics', {'artist': artist, 'title': title});
 final l = sub['lyrics'] as Map<String, dynamic>?;
 if (l == null || l['value'] == null) return null;
 return Lyrics(artist: l['artist'] ?? artist, title: l['title'] ?? title, text: l['value']);
 }

 // ---- Media annotation ----
 Future<void> star(String id) => _get('star', {'id': id});
 Future<void> unstar(String id) => _get('unstar', {'id': id});
 Future<void> scrobble(String id) => _get('scrobble', {'id': id, 'submission': true});

 // ---- Play queue ----
 Future<List<SubsonicSong>> getPlayQueue() async {
 final sub = await _get('getPlayQueue');
 final pq = sub['playQueue'] as Map<String, dynamic>?;
 if (pq == null) return [];
 final list = pq['entry'] as List? ?? [];
 return list.cast<Map<String, dynamic>>().map(SubsonicSong.fromJson).toList();
 }

 Future<void> savePlayQueue(List<String> ids, {String? current}) async {
 final p = <String, dynamic>{'id': ids.join(',')};
 if (current != null) p['current'] = current;
 await _get('savePlayQueue', p);
 }
}

class Lyrics {
 final String artist;
 final String title;
 final String text;
 Lyrics({required this.artist, required this.title, required this.text});
}

class SubsonicException implements Exception {
 final int code;
 final String message;
 SubsonicException(this.code, this.message);

 @override
 String toString() => 'SubsonicException($code): $message';
}