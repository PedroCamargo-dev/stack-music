import 'dart:io';

import '../models/subsonic_models.dart';

/// Decide de onde uma faixa será reproduzida: arquivo offline válido primeiro,
/// stream do servidor como fallback.
class TrackUriResolver {
  const TrackUriResolver({
    required this.streamUrlFor,
    required this.localPathFor,
  });

  final String Function(String trackId) streamUrlFor;
  final String? Function(String trackId) localPathFor;

  Uri resolve(SubsonicSong song) {
    final localPath = localPathFor(song.id);
    if (localPath != null && File(localPath).existsSync()) {
      return Uri.file(localPath);
    }
    return Uri.parse(streamUrlFor(song.id));
  }
}
