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
import 'package:stack_music/features/album/album_screen.dart';

import '../support/performance_fixtures.dart';

class _AlbumClient extends SubsonicClient {
  _AlbumClient(this.album, this.songs)
      : super(
          baseUrl: 'https://music.example.test',
          username: 'alice',
          password: 'test-only',
          dio: Dio(),
        );

  final SubsonicAlbum album;
  final List<SubsonicSong> songs;

  @override
  Future<SubsonicAlbum> getAlbum(String id) async => album;

  @override
  Future<List<SubsonicSong>> getSongsOfAlbum(String albumId) async => songs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('botão de download do álbum cria job com todas as faixas',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    SharedPreferences.setMockInitialValues({});
    final album = SubsonicAlbum(
      id: 'album-1',
      name: 'Offline Album',
      artist: 'Artist',
      songCount: 2,
    );
    final songs = [
      SubsonicSong(
        id: 'song-1',
        title: 'One',
        artist: 'Artist',
        album: album.name,
        albumId: album.id,
      ),
      SubsonicSong(
        id: 'song-2',
        title: 'Two',
        artist: 'Artist',
        album: album.name,
        albumId: album.id,
      ),
    ];
    final client = _AlbumClient(album, songs);
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
        child: MaterialApp(home: AlbumScreen(album: album)),
      ),
    );
    await tester.pumpAndSettle();

    final downloadButton = find.byTooltip('Baixar álbum');
    await tester.tap(downloadButton);
    await tester.pumpAndSettle();

    expect(store.jobs, hasLength(1));
    expect(store.jobs.single.id, 'album-${album.id}');
    expect(store.jobs.single.trackIds, ['song-1', 'song-2']);
  });
}
