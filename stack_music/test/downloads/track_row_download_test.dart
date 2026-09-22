import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_music/core/app_state.dart';
import 'package:stack_music/core/models/subsonic_models.dart';
import 'package:stack_music/core/offline/download_store.dart';
import 'package:stack_music/core/offline/offline_downloader.dart';
import 'package:stack_music/shared/widgets.dart';

import '../support/performance_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TrackRow enfileira a faixa para download', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final client = FixtureClient();
    final store = DownloadStore();
    await store.load();
    final app = TestAppState(client)
      ..downloadStore = store
      ..downloader = OfflineDownloader(
        client,
        store,
        mayDownload: () => false,
      );
    final song = SubsonicSong(
      id: 'song-download',
      title: 'Download Me',
      artist: 'Artist',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          home: Scaffold(
            body: TrackRow(song: song, queue: [song]),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Download Me'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baixar faixa'));
    await tester.pumpAndSettle();

    expect(store.jobs, hasLength(1));
    expect(store.jobs.single.trackIds, [song.id]);
  });
}
