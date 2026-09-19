import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/subsonic_client.dart';
import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Now Playing (refs 17.43.15, 17.48.19, 17.49.44, 17.48.51):
/// gradiente índigo, capa grande central, like/repeat/shuffle, progresso,
/// "SWIPE UP FOR LYRICS".
class NowPlayingScreen extends StatefulWidget {
 const NowPlayingScreen({super.key});

 @override
 State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
 Lyrics? _lyrics;
 bool _lyricsOpen = false;

 Future<void> _loadLyrics(SubsonicSong song) async {
 try {
 final l = await context.read<AppState>().subsonic!.getLyrics(song.artist, song.title);
 if (mounted) setState(() => _lyrics = l);
 } catch (_) {
 if (mounted) setState(() => _lyrics = null);
 }
 }

 @override
 Widget build(BuildContext context) {
 final app = context.watch<AppState>();
 final state = app.player;
 final song = state?.currentSong;
 if (song == null) {
 return const Scaffold(body: Center(child: Text('Nada tocando')));
 }
 if (_lyrics == null) _loadLyrics(song);

 return Scaffold(
 body: Container(
 decoration: const BoxDecoration(
 gradient: LinearGradient(
 begin: Alignment.topCenter,
 end: Alignment.bottomCenter,
 colors: [AppColors.playerGradientStart, AppColors.playerGradientEnd],
 ),
 ),
 child: SafeArea(
 child: GestureDetector(
 onVerticalDragEnd: (d) {
 if ((d.primaryVelocity ?? 0) > 0) Navigator.of(context).pop();
 if ((d.primaryVelocity ?? 0) < 0 && _lyrics != null) {
 setState(() => _lyricsOpen = true);
 }
 },
 child: Column(children: [
 // Topo: voltar + hint de letras (ref 17.43.15)
 Row(children: [
 IconButton(
 icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
 onPressed: () => Navigator.of(context).pop(),
 ),
 const Expanded(
 child: Text('SWIPE UP FOR LYRICS',
 textAlign: TextAlign.center,
 style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: Colors.white70)),
 ),
 const SizedBox(width: 48),
 ]),
 Expanded(
 child: _lyricsOpen && _lyrics != null
 ? ListView(
 padding: const EdgeInsets.all(24),
 children: [
 Text(_lyrics!.title, textAlign: TextAlign.center,
 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
 const SizedBox(height: 16),
 Text(_lyrics!.text,
 style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.white70)),
 ],
 )
 : Center(
 child: Column(mainAxisSize: MainAxisSize.min, children: [
 Hero(
 tag: 'cover-${song.id}',
 child: CoverArt(coverArtId: song.coverArt, size: 280, radius: 24)),
 const SizedBox(height: 32),
 Text(song.title,
 textAlign: TextAlign.center,
 style: const TextStyle(
 fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
 const SizedBox(height: 4),
 Text(song.artist,
 style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
 ]),
 ),
 ),
 // Ações: like / repeat / shuffle / more
 Row(mainAxisAlignment: MainAxisAlignment.center, children: [
 IconButton(
 icon: Icon(song.starred ? Icons.favorite : Icons.favorite_border, color: Colors.white),
 onPressed: () async {
 final client = app.subsonic!;
 try {
 song.starred ? await client.unstar(song.id) : await client.star(song.id);
 setState(() => song.starred = !song.starred);
 } catch (_) {}
 },
 ),
 IconButton(
 icon: Icon(Icons.download, color: Colors.white),
 onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(content: Text('Baixando ${song.title}... (via servidor)'))),
 ),
 ]),
 // Progresso + tempos
 StreamBuilder<Duration>(
 stream: state!.player.positionStream,
 builder: (_, snap) {
 final pos = snap.data ?? Duration.zero;
 final total = Duration(seconds: song.duration);
 return Column(children: [
 SliderTheme(
 data: SliderTheme.of(context).copyWith(
 trackHeight: 3,
 overlayShape: const RoundSliderOverlayShape(overlayRadius: 12)),
 child: Slider(
 value: total.inSeconds == 0 ? 0 : pos.inSeconds.clamp(0, total.inSeconds).toDouble(),
 max: total.inSeconds == 0 ? 1 : total.inSeconds.toDouble(),
 onChanged: (v) => state.player.seek(Duration(seconds: v.toInt())),
 ),
 ),
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 24),
 child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
 Text(_fmt(pos), style: const TextStyle(fontSize: 12, color: Colors.white70)),
 Text(_fmt(total), style: const TextStyle(fontSize: 12, color: Colors.white70)),
 ])),
 ]);
 },
 ),
 // Controles principais
 Padding(
 padding: const EdgeInsets.only(bottom: 16),
 child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
 IconButton(
 icon: const Icon(Icons.shuffle, color: Colors.white70, size: 26),
 onPressed: () => state.toggleShuffle()),
 IconButton(
 icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
 onPressed: () => state.skipToPrevious()),
 Container(
 width: 84,
 height: 84,
 decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
 child: IconButton(
 iconSize: 40,
 color: Colors.black,
 icon: Icon(state.player.playing ? Icons.pause : Icons.play_arrow),
 onPressed: () => state.player.playing ? state.pause() : state.play(),
 ),
 ),
 IconButton(
 icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
 onPressed: () => state.skipToNext()),
 StreamBuilder<AudioServiceRepeatMode>(
 stream: state.playbackState.map((s) => s.repeatMode).distinct(),
 builder: (_, snap) => IconButton(
 icon: Icon(Icons.repeat,
 color: snap.data == AudioServiceRepeatMode.none ? Colors.white70 : AppColors.primary,
 size: 26),
 onPressed: () => state.setRepeatMode(
 snap.data == AudioServiceRepeatMode.none
 ? AudioServiceRepeatMode.all
 : AudioServiceRepeatMode.none)),
 ),
 ]),
 ),
 ]),
 ),
 ),
 ),
 );
 }

 String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}