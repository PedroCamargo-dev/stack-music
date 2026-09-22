import 'package:flutter_test/flutter_test.dart';
import 'package:stack_music/core/models/subsonic_models.dart';

void main() {
  test('SubsonicSong preserva formato e content type para download offline', () {
    final dynamic song = SubsonicSong.fromJson({
      'id': 'song-flac',
      'title': 'Lossless',
      'artist': 'Artist',
      'suffix': 'flac',
      'contentType': 'audio/flac',
      'bitRate': 950,
    });

    expect(song.suffix, 'flac');
    expect(song.contentType, 'audio/flac');
    expect(song.bitRate, 950);
  });
}
