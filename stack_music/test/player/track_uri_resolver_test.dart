import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stack_music/core/models/subsonic_models.dart';
import 'package:stack_music/core/player/track_uri_resolver.dart';

void main() {
  final song = SubsonicSong(
    id: 'song-1',
    title: 'Track',
    artist: 'Artist',
  );

  test('usa arquivo local quando a faixa está baixada', () async {
    final directory = await Directory.systemTemp.createTemp('track-uri-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/song-1.flac');
    await file.writeAsBytes([1, 2, 3]);
    final resolver = TrackUriResolver(
      streamUrlFor: (id) => 'https://music.example.test/stream/$id',
      localPathFor: (id) => id == song.id ? file.path : null,
    );

    expect(resolver.resolve(song), Uri.file(file.path));
  });

  test('usa stream quando não existe arquivo local válido', () {
    final resolver = TrackUriResolver(
      streamUrlFor: (id) => 'https://music.example.test/stream/$id',
      localPathFor: (_) => '/path/que/nao/existe.flac',
    );

    expect(
      resolver.resolve(song),
      Uri.parse('https://music.example.test/stream/song-1'),
    );
  });
}
