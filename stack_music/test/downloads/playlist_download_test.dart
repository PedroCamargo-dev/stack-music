import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_music/core/api/subsonic_client.dart';
import 'package:stack_music/core/app_state.dart';
import 'package:stack_music/core/models/subsonic_models.dart';
import 'package:stack_music/core/offline/download_store.dart';
import 'package:stack_music/core/offline/offline_downloader.dart';
import 'package:stack_music/features/playlist/playlist_screen.dart';

import '../support/performance_fixtures.dart';

class _PlaylistClient extends SubsonicClient {
  _PlaylistClient(this.playlist, this.songs)
      : super(
          baseUrl: 'https://music.example.test',
          username: 'alice',
          password: 'test-only',
          dio: Dio(),
        );

  final SubsonicPlaylist playlist;
  final List<SubsonicSong> songs;

  @override
  Future<List<SubsonicSong>> getPlaylistSongs(String playlistId) async => songs;

  @override
  Future<List<SubsonicPlaylist>> getPlaylists() async => [playlist];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('botão de download da playlist cria job com todas as faixas',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues({});
    final playlist = SubsonicPlaylist(
      id: 'playlist-1',
      name: 'Offline Playlist',
      songCount: 2,
      owner: 'alice',
    );
    final songs = [
      SubsonicSong(id: 'song-1', title: 'One', artist: 'Artist'),
      SubsonicSong(id: 'song-2', title: 'Two', artist: 'Artist'),
    ];
    final client = _PlaylistClient(playlist, songs);
    final store = DownloadStore();
    await store.load();
    final app = TestAppState(FixtureClient())
      ..subsonic = client
      ..downloadStore = store
      ..downloader = OfflineDownloader(
        client,
        store,
        mayDownload: () => false,
      );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(home: PlaylistScreen(playlist: playlist)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Baixar playlist'));
    await tester.pumpAndSettle();

    expect(store.jobs, hasLength(1));
    expect(store.jobs.single.id, 'playlist-${playlist.id}');
    expect(store.jobs.single.trackIds, ['song-1', 'song-2']);
  });
}
