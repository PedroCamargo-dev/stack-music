import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../api/subsonic_client.dart';
import '../models/subsonic_models.dart';
import 'track_uri_resolver.dart';

/// Handler do audio_service: expõe controles na notificação/lock screen,
/// mantém fila, shuffle, repeat e faz scrobble ao completar faixa.
class PlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
 final SubsonicClient client;
 final AudioPlayer player = AudioPlayer();
 late final TrackUriResolver _uriResolver;

 final List<SubsonicSong> _queue = [];
 int _index = -1;
 bool _shuffle = false;
 bool _scrobbled = false;

 PlayerHandler(
   this.client, {
   String? Function(String trackId)? localPathFor,
 }) {
 _uriResolver = TrackUriResolver(
   streamUrlFor: client.streamUrl,
   localPathFor: localPathFor ?? (_) => null,
 );
 player.playbackEventStream.map(_toState).pipe(playbackState);
 player.sequenceStateStream.listen(_onSequenceChanged);
 player.playerStateStream.listen((s) {
 if (s.processingState == ProcessingState.completed) {
 _scrobbleIfDue();
 skipToNext();
 }
 });
 }

 List<SubsonicSong> get songs => _queue;
 SubsonicSong? get currentSong =>
 _index >= 0 && _index < _queue.length ? _queue[_index] : null;

 void _onSequenceChanged(SequenceState? state) {
 final i = state?.currentIndex ?? -1;
 if (i != _index) {
 _index = i;
 _scrobbled = false;
 mediaItem.add(_toMediaItem(currentSong));
 }
 }

 PlaybackState _toState(PlaybackEvent event) => PlaybackState(
 controls: [
 MediaControl.skipToPrevious,
 if (player.playing) MediaControl.pause else MediaControl.play,
 MediaControl.skipToNext,
 ],
 systemActions: const {
 MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward,
 },
 androidCompactActionIndices: const [0, 1, 2],
 processingState: const {
 ProcessingState.idle: AudioProcessingState.idle,
 ProcessingState.loading: AudioProcessingState.loading,
 ProcessingState.buffering: AudioProcessingState.buffering,
 ProcessingState.ready: AudioProcessingState.ready,
 ProcessingState.completed: AudioProcessingState.completed,
 }[player.processingState]!,
 playing: player.playing,
 updatePosition: player.position,
 bufferedPosition: player.bufferedPosition,
 speed: player.speed,
 );

  MediaItem _toMediaItem(SubsonicSong? s) {
    if (s == null) return const MediaItem(id: '', title: '');
    return MediaItem(
      id: s.id,
      title: s.title,
      artist: s.artist,
      album: s.album,
      duration: Duration(seconds: s.duration),
      artUri: client.coverArtUrl(s.coverArt).isEmpty
          ? null
          : Uri.tryParse(client.coverArtUrl(s.coverArt, size: 300)),
      extras: {
        'coverArt': s.coverArt,
        'artistId': s.artistId,
        'albumId': s.albumId,
        'starred': s.starred,
      },
    );
  }

 void _scrobbleIfDue() {
 final s = currentSong;
 if (s != null && !_scrobbled) {
 _scrobbled = true;
 client.scrobble(s.id).catchError((_) {});
 }
 }

  /// Monta a fila com fontes de stream e reproduz a partir de [startIndex].
  Future<void> playQueue(List<SubsonicSong> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    _queue
      ..clear()
      ..addAll(songs);
    _index = startIndex.clamp(0, songs.length - 1);
    _scrobbled = false;
    mediaItem.add(_toMediaItem(currentSong));

    final source = ConcatenatingAudioSource(
      children: songs
          .map((song) => AudioSource.uri(_uriResolver.resolve(song)))
          .toList(),
    );
    await player.setAudioSource(source, initialIndex: _index);
    play();
  }

 @override
 Future<void> play() => player.play();
 @override
 Future<void> pause() => player.pause();

 @override
 Future<void> seek(Duration position) => player.seek(position);

 @override
 Future<void> skipToNext() {
 _scrobbleIfDue();
 return player.seekToNext();
 }

 @override
 Future<void> skipToPrevious() => player.seekToPrevious();

 @override
 Future<void> stop() async {
 await player.stop();
 _queue.clear();
 _index = -1;
 await super.stop();
 }

 @override
 Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
 _shuffle = shuffleMode != AudioServiceShuffleMode.none;
 if (shuffleMode == AudioServiceShuffleMode.all) {
 await player.shuffle();
 }
 return super.setShuffleMode(shuffleMode);
 }

 bool get isShuffled => _shuffle;

 Future<void> toggleShuffle() => setShuffleMode(
 _shuffle ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all);

 /// Toca uma URL arbitrária (ex.: stream de rádio internet) fora da fila.
 Future<void> playUrl(String url, {String title = ''}) async {
 _queue.clear();
 _index = -1;
 mediaItem.add(MediaItem(id: url, title: title.isEmpty ? 'Rádio' : title));
 await player.setUrl(url);
 play();
 }

 /// Remove uma faixa da fila pelo índice (QueueSheet). Se for a atual,
/// avança para a próxima (ou para se for a última).
 Future<void> removeAt(int index) async {
 if (index < 0 || index >= _queue.length) return;
 _queue.removeAt(index);
 final source = player.audioSource;
 if (source is ConcatenatingAudioSource) {
 try {
 await source.removeAt(index);
 } catch (_) {
 // índice fora da fonte: reconstroi a fila
 await _rebuildSource();
 }
 }
 if (_index >= _queue.length) {
 _index = _queue.length - 1;
 }
 }

 Future<void> _rebuildSource() async {
 final src = ConcatenatingAudioSource(
 children: _queue
     .map((song) => AudioSource.uri(_uriResolver.resolve(song)))
     .toList());
 await player.setAudioSource(src,
 initialIndex: _index < 0 ? 0 : (_index < _queue.length ? _index : 0),
 initialPosition: Duration.zero);
 }

 /// Adiciona ao fim da fila atual.
 Future<void> addToQueue(SubsonicSong song) async {
 _queue.add(song);
 await (player.audioSource as ConcatenatingAudioSource)
 .add(AudioSource.uri(_uriResolver.resolve(song)));
 }

 Future<void> savePlayQueue() async {
 if (_queue.isEmpty) return;
 final ids = _queue.map((s) => s.id).toList();
 client.savePlayQueue(ids, current: currentSong?.id).catchError((_) {});
 }
}