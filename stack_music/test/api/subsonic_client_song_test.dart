import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_music/core/api/subsonic_client.dart';

void main() {
  test('getSong resolve metadados atuais da faixa pelo ID', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        expect(options.uri.path, endsWith('/rest/getSong.view'));
        expect(options.uri.queryParameters['id'], 'song-1');
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'subsonic-response': {
              'status': 'ok',
              'song': {
                'id': 'song-1',
                'title': 'Offline Track',
                'artist': 'Offline Artist',
                'album': 'Offline Album',
              },
            },
          },
        ));
      },
    ));
    final dynamic client = SubsonicClient(
      baseUrl: 'https://music.example.test',
      username: 'alice',
      password: 'test-only',
      dio: dio,
    );

    final song = await client.getSong('song-1');

    expect(song.id, 'song-1');
    expect(song.title, 'Offline Track');
  });
}
