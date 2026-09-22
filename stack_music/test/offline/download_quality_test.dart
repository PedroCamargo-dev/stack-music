import 'package:flutter_test/flutter_test.dart';
import 'package:stack_music/core/api/subsonic_client.dart';
import 'package:stack_music/core/offline/download_quality.dart';

void main() {
  final client = SubsonicClient(
    baseUrl: 'https://music.example.test',
    username: 'alice',
    password: 'test-only',
  );

  test('qualidade original usa endpoint download', () {
    final uri = Uri.parse(DownloadQuality.original.urlFor(client, 'song-1'));

    expect(uri.path, endsWith('/rest/download.view'));
    expect(uri.queryParameters['id'], 'song-1');
    expect(uri.queryParameters.containsKey('maxBitRate'), isFalse);
  });

  test('qualidades transcodificadas usam stream com bitrate configurado', () {
    final cases = {
      DownloadQuality.high: '320',
      DownloadQuality.medium: '192',
      DownloadQuality.low: '128',
    };

    for (final entry in cases.entries) {
      final uri = Uri.parse(entry.key.urlFor(client, 'song-1'));
      expect(uri.path, endsWith('/rest/stream.view'));
      expect(uri.queryParameters['maxBitRate'], entry.value);
    }
  });

  test('valor persistido inválido volta para original', () {
    expect(DownloadQuality.fromStorage('invalid'), DownloadQuality.original);
    expect(DownloadQuality.fromStorage('medium'), DownloadQuality.medium);
  });
}
