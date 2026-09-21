import 'package:dio/dio.dart';
import 'package:stack_music/core/api/subsonic_client.dart';
import 'package:stack_music/core/app_state.dart';

// Synthetic test data only. No real credentials, HTTP, or audio platform.
class FixtureClient extends SubsonicClient {
  final List<String> requests = [];

  FixtureClient()
      : super(
          baseUrl: 'https://music.example.test',
          username: 'Alice',
          password: 'test-only',
          dio: Dio(),
        ) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final endpoint = options.uri.pathSegments.last.replaceAll('.view', '');
      requests.add(endpoint);
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'subsonic-response': {
            'status': 'ok',
            'artists': {
              'index': [
                {
                  'artist': [
                    {'id': 'artist-a', 'name': 'Test Artist', 'albumCount': 3}
                  ]
                }
              ]
            },
            'albumList2': {
              'album': [
                {'id': 'album-a', 'name': 'Test Album', 'artist': 'Test Artist'}
              ]
            },
            'randomSongs': {
              'song': [
                {'id': 'song-a', 'title': 'Test Song', 'artist': 'Test Artist'}
              ]
            },
            'starred2': {'song': [], 'artist': []},
            'playlists': {'playlist': []},
            'genres': [],
          },
        },
      ));
    }));
  }
}

class TestAppState extends AppState {
  TestAppState(FixtureClient client) {
    subsonic = client;
  }

  @override
  bool get ready => true;

  void unrelatedChange() => notifyListeners();

  void rename(String name) {
    subsonic!.username = name;
    notifyListeners();
  }
}
