import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_music/core/offline/download_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('reenfileirar um job preserva a data original de criação', () async {
    final store = DownloadStore();

    await store.enqueueJob(const DownloadJob(
      id: 'album-1',
      type: 'album',
      collectionId: 'album-1',
      trackIds: ['song-1'],
      createdAt: 100,
      updatedAt: 100,
    ));
    final originalCreatedAt = store.jobs.single.createdAt;

    await store.enqueueJob(const DownloadJob(
      id: 'album-1',
      type: 'album',
      collectionId: 'album-1',
      trackIds: ['song-1', 'song-2'],
      createdAt: 999,
      updatedAt: 999,
    ));

    expect(store.jobs.single.createdAt, originalCreatedAt);
    expect(store.jobs.single.trackIds, ['song-1', 'song-2']);
  });

  test('dados persistidos corrompidos não impedem o store de carregar', () async {
    SharedPreferences.setMockInitialValues({
      'offline_tracks': '{not-json',
      'offline_jobs': '[broken',
      'offline_resumables': 'null',
    });
    final store = DownloadStore();

    await expectLater(store.load(), completes);

    expect(store.tracks, isEmpty);
    expect(store.jobs, isEmpty);
    expect(store.resumables, isEmpty);
  });
}
