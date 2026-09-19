import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Tela de playlist (ref 17.48.51): header "PLAYLIST" + nome, lista de faixas,
/// faixa ativa com barra de progresso, Play all.
class PlaylistScreen extends StatefulWidget {
 final SubsonicPlaylist playlist;
 const PlaylistScreen({super.key, required this.playlist});

 @override
 State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
 List<SubsonicSong> songs = [];
 bool loading = true;
 String? error;

 @override
 void initState() {
 super.initState();
 _load();
 }

 Future<void> _load() async {
 setState(() { loading = true; error = null; });
 try {
 final s = await context.read<AppState>().subsonic!.getPlaylistSongs(widget.playlist.id);
 setState(() { songs = s; loading = false; });
 } catch (e) {
 setState(() { loading = false; error = e.toString(); });
 }
 }

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 final textP = AppColors.textPrimary(b);
 final textS = AppColors.textSecondary(b);
 final player = context.watch<AppState>().player;

 return Scaffold(
 body: SafeArea(
 child: loading
 ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
 : error != null
 ? Center(child: Text('Erro: $error'))
 : ListView(
 padding: const EdgeInsets.only(bottom: 24),
 children: [
 Row(children: [
 IconButton(
 icon: Icon(Icons.arrow_back, color: textP),
 onPressed: () => Navigator.of(context).pop(),
 ),
 ]),
 // Header (ref 17.48.51)
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 16),
 child: Row(children: [
 CoverArt(coverArtId: widget.playlist.coverArt, size: 120),
 const SizedBox(width: 16),
 Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 Text('PLAYLIST', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: textS)),
 const SizedBox(height: 4),
 Text(widget.playlist.name,
 style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textP)),
 const SizedBox(height: 4),
 Text('${widget.playlist.songCount} songs'
 '${widget.playlist.owner != null ? ' · ${widget.playlist.owner}' : ''}',
 style: TextStyle(fontSize: 12, color: textS)),
 ])),
 ]),
 ),
 const SizedBox(height: 16),
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 16),
 child: Row(children: [
 FilledButton.icon(
 style: FilledButton.styleFrom(
 backgroundColor: AppColors.primary, foregroundColor: Colors.black),
 onPressed: () => player?.playQueue(songs),
 icon: const Icon(Icons.play_arrow),
 label: const Text('Play all'),
 ),
 const SizedBox(width: 8),
 OutlinedButton.icon(
 onPressed: () => player?.toggleShuffle(),
 icon: const Icon(Icons.shuffle, size: 18),
 label: const Text('Shuffle'),
 ),
 ]),
 ),
 const SizedBox(height: 8),
 for (final s in songs)
 _PlaylistSongTile(song: s, queue: songs),
 ],
 ),
 ),
 );
 }
}

/// Tile com estado de playing (ícone pause + barra de progresso na faixa ativa).
class _PlaylistSongTile extends StatelessWidget {
 final SubsonicSong song;
 final List<SubsonicSong> queue;
 const _PlaylistSongTile({required this.song, required this.queue});

 @override
 Widget build(BuildContext context) {
 final state = context.read<AppState>().player;
 final b = Theme.of(context).brightness;
 final isCurrent = state?.currentSong?.id == song.id;

 return Column(children: [
 ListTile(
 onTap: () => state?.playQueue(queue, startIndex: queue.indexOf(song)),
 leading: CoverArt(coverArtId: song.coverArt, size: 48, radius: 8),
 title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 15,
 fontWeight: FontWeight.w600,
 color: isCurrent ? AppColors.primary : AppColors.textPrimary(b))),
 subtitle: Text(song.artist, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(b))),
 trailing: Row(mainAxisSize: MainAxisSize.min, children: [
 if (isCurrent)
 Icon(state!.player.playing ? Icons.pause : Icons.play_arrow,
 size: 20, color: AppColors.primary),
 const SizedBox(width: 8),
 Text(song.durationLabel, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(b))),
 ]),
 ),
 if (isCurrent)
 StreamBuilder<Duration>(
 stream: state!.player.positionStream,
 builder: (_, snap) {
 final pos = snap.data ?? Duration.zero;
 final total = Duration(seconds: song.duration);
 return Padding(
 padding: const EdgeInsets.symmetric(horizontal: 24),
 child: LinearProgressIndicator(
 value: total.inSeconds == 0 ? 0 : pos.inSeconds / total.inSeconds,
 minHeight: 2,
 backgroundColor: AppColors.surface2(b),
 valueColor: const AlwaysStoppedAnimation(AppColors.primary),
 ),
 );
 },
 ),
 ]);
 }
}