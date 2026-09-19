import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/models/subsonic_models.dart';
import '../core/theme/app_theme.dart';

/// Capa quadrada 1:1 via getCoverArt, com placeholder de nota musical.
class CoverArt extends StatelessWidget {
 final String? coverArtId;
 final double size;
 final double radius;

 const CoverArt({super.key, this.coverArtId, this.size = 160, this.radius = 16});

 @override
 Widget build(BuildContext context) {
 final url = context.read<AppState>().subsonic?.coverArtUrl(coverArtId, size: 600) ?? '';
 if (url.isEmpty) {
 return _placeholder(context);
 }
 return ClipRRect(
 borderRadius: BorderRadius.circular(radius),
 child: CachedNetworkImage(
 imageUrl: url,
 width: size,
 height: size,
 fit: BoxFit.cover,
 placeholder: (_, __) => _placeholder(context),
 errorWidget: (_, __, ___) => _placeholder(context),
 ),
 );
 }

 Widget _placeholder(BuildContext context) => Container(
 width: size,
 height: size,
 decoration: BoxDecoration(
 color: AppColors.surface2(Theme.of(context).brightness),
 borderRadius: BorderRadius.circular(radius),
 ),
 child: Icon(Icons.music_note, color: AppColors.textSecondary(Theme.of(context).brightness), size: size * 0.35),
 );
}

/// Card horizontal de faixa (lista/playlist): capa, título, artista, duração,
/// like e menu. Toca a faixa na fila passada.
class SongTile extends StatelessWidget {
 final SubsonicSong song;
 final List<SubsonicSong> queue;
 final VoidCallback? onDownload;

 const SongTile({super.key, required this.song, required this.queue, this.onDownload});

 @override
 Widget build(BuildContext context) {
 final app = context.read<AppState>();
 final state = app.player;
 final b = Theme.of(context).brightness;
 final isCurrent = state?.currentSong?.id == song.id;

 return ListTile(
 onTap: () => state?.playQueue(queue, startIndex: queue.indexOf(song)),
 leading: CoverArt(coverArtId: song.coverArt, size: 48, radius: 8),
 title: Text(
 song.title,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 15,
 fontWeight: FontWeight.w600,
 color: isCurrent ? AppColors.primary : AppColors.textPrimary(b),
 ),
 ),
 subtitle: Text(song.artist, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(b))),
 trailing: Row(mainAxisSize: MainAxisSize.min, children: [
 if (isCurrent && state?.player.playing == true)
 const SizedBox(
 width: 16, height: 12,
 child: Icon(Icons.graphic_eq, size: 16, color: AppColors.primary)),
 IconButton(
 icon: Icon(
 song.starred ? Icons.favorite : Icons.favorite_border,
 size: 20,
 color: song.starred ? AppColors.primary : AppColors.textSecondary(b),
 ),
 onPressed: () async {
 final client = app.subsonic!;
 try {
 song.starred ? await client.unstar(song.id) : await client.star(song.id);
 song.starred = !song.starred;
 } catch (_) {}
 // força rebuild
 (context as Element).markNeedsBuild();
 },
 ),
 Text(song.durationLabel, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(b))),
 ]),
 );
 }
}

/// Mini-player fixo acima da bottom nav (ref 17.48.51).
class MiniPlayer extends StatelessWidget {
 const MiniPlayer({super.key});

 @override
 Widget build(BuildContext context) {
 final state = context.watch<AppState>().player;
 final song = state?.currentSong;
 if (song == null) return const SizedBox.shrink();

 return GestureDetector(
 onTap: () => Navigator.of(context).pushNamed('/nowplaying'),
 child: Container(
 margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 decoration: BoxDecoration(
 color: AppColors.primary,
 borderRadius: BorderRadius.circular(999),
 ),
 child: Row(children: [
 CoverArt(coverArtId: song.coverArt, size: 36, radius: 8),
 const SizedBox(width: 10),
 Expanded(
 child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
 Text(song.artist, maxLines: 1,
 style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.7))),
 ]),
 ),
 StreamBuilder<Duration>(
 stream: state!.player.positionStream,
 builder: (_, snap) {
 final pos = snap.data ?? Duration.zero;
 final total = Duration(seconds: song.duration);
 return SizedBox(
 width: 48,
 child: LinearProgressIndicator(
 value: total.inSeconds == 0 ? 0 : pos.inSeconds / total.inSeconds,
 backgroundColor: Colors.black.withValues(alpha: 0.2),
 valueColor: const AlwaysStoppedAnimation(Colors.black),
 ),
 );
 },
 ),
 IconButton(
 icon: Icon(state.player.playing ? Icons.pause : Icons.play_arrow, color: Colors.black),
 onPressed: () => state.player.playing ? state.pause() : state.play(),
 ),
 ]),
 ),
 );
 }
}

/// Header de seção com link "Show all" (refs Home).
class SectionHeader extends StatelessWidget {
 final String title;
 final VoidCallback? onShowAll;

 const SectionHeader({super.key, required this.title, this.onShowAll});

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 return Padding(
 padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(b))),
 if (onShowAll != null)
 GestureDetector(
 onTap: onShowAll,
 child: Text('Show all',
 style: TextStyle(fontSize: 13, color: AppColors.secondaryAccent)),
 ),
 ],
 ),
 );
 }
}