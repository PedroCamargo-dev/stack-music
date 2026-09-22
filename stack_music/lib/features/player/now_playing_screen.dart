import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/lrclib_client.dart';
import '../../core/api/subsonic_client.dart';
import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/player/player_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/star_rating.dart';
import '../../shared/widgets.dart';

/// Full Player — RECONSTRUÇÃO VISUAL:
/// - background imersivo: capa desfocada + overlay escuro (tokens preservados);
/// - artwork grande (~82% da largura), centralizada, com sombra;
/// - metadata à esquerda (título grande, artista clicável) + like;
/// - progress com seek + tempos;
/// - PLAY dominante (1.6x) entre previous/next; shuffle/repeat nas pontas;
/// - ações inferiores reais: Fila e Letras (quando existirem);
/// - swipe-down fecha; swipe-up abre letras.
class NowPlayingScreen extends StatefulWidget {
 const NowPlayingScreen({super.key});

 @override
 State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  Lyrics? _lyrics;
  bool _lyricsOpen = false;
  LrcLibClient? _lrcClient;

  @override
  void dispose() {
    _lrcClient?.dispose();
    super.dispose();
  }

 Future<void> _loadLyrics(SubsonicSong song) async {
     try {
       final l = await context
           .read<AppState>()
           .subsonic!
           .getLyrics(song.artist, song.title);
       if (l != null && l.text.isNotEmpty) {
         if (mounted) setState(() => _lyrics = l);
         return;
       }
     } catch (_) {}

     // Fallback: LRCLib (letras sincronizadas ou texto puro)
     try {
       _lrcClient?.dispose();
       _lrcClient = LrcLibClient();
       final result = await _lrcClient!.getLyrics(song.artist, song.title);
       if (result?.bestText != null && result!.bestText!.isNotEmpty) {
         if (mounted) {
           setState(() {
             _lyrics = Lyrics(
               artist: result.artist,
               title: result.title,
               text: result.bestText!,
             );
           });
         }
       } else if (mounted) {
         setState(() => _lyrics = null);
       }
     } catch (_) {
       if (mounted) setState(() => _lyrics = null);
     }
   }

 void _openQueue() {
     showModalBottomSheet<void>(
       context: context,
       isScrollControlled: true,
       builder: (_) => const QueueSheet(),
     );
   }

   void _showSleepTimerSheet(PlayerHandler state) {
     showModalBottomSheet<void>(
       context: context,
       builder: (ctx) => SafeArea(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             ListTile(
               title: const Text('15 min'),
               onTap: () {
                 state.setSleepTimer(const Duration(minutes: 15));
                 Navigator.pop(ctx);
               },
             ),
             ListTile(
               title: const Text('30 min'),
               onTap: () {
                 state.setSleepTimer(const Duration(minutes: 30));
                 Navigator.pop(ctx);
               },
             ),
             ListTile(
               title: const Text('45 min'),
               onTap: () {
                 state.setSleepTimer(const Duration(minutes: 45));
                 Navigator.pop(ctx);
               },
             ),
             ListTile(
               title: const Text('60 min'),
               onTap: () {
                 state.setSleepTimer(const Duration(hours: 1));
                 Navigator.pop(ctx);
               },
             ),
             if (state.isSleepTimerActive)
               ListTile(
                 title: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                 onTap: () {
                   state.cancelSleepTimer();
                   Navigator.pop(ctx);
                 },
               ),
           ],
         ),
       ),
     );
   }

   void _showSpeedSheet(PlayerHandler state) {
     final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
     showModalBottomSheet<void>(
       context: context,
       builder: (ctx) => SafeArea(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: speeds.map((s) => ListTile(
             title: Text('${s.toStringAsFixed(2)}x'),
             trailing: state.playbackSpeed == s ? const Icon(Icons.check) : null,
             onTap: () async {
               await state.setPlaybackSpeed(s);
               if (mounted) setState(() {});
               if (ctx.mounted) Navigator.pop(ctx);
             },
           )).toList(),
         ),
       ),
     );
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

 final coverUrl = app.subsonic?.coverArtUrl(song.coverArt, size: 600) ?? '';
 final w = MediaQuery.of(context).size.width;

 return Scaffold(
 body: Stack(
 fit: StackFit.expand,
 children: [
 // BACKGROUND imersivo: capa desfocada + overlay escuro
 if (coverUrl.isNotEmpty)
 ImageFiltered(
 imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
 child: CachedNetworkImage(
 imageUrl: coverUrl,
 fit: BoxFit.cover,
 width: double.infinity,
 height: double.infinity,
 errorWidget: (_, __, ___) =>
 Container(color: AppColors.playerGradientStart),
 ),
 ),
 Container(color: Colors.black.withValues(alpha: 0.55)),
 // CONTEÚDO
 SafeArea(
 child: GestureDetector(
 onVerticalDragEnd: (d) {
 if ((d.primaryVelocity ?? 0) > 0) {
 Navigator.of(context).pop();
 }
 if ((d.primaryVelocity ?? 0) < 0 && _lyrics != null) {
 setState(() => _lyricsOpen = true);
 }
 },
 child: Column(children: [
 // TOPO: fechar + título + queue
 Row(children: [
 IconButton(
 icon: const Icon(Icons.keyboard_arrow_down,
 color: Colors.white, size: 32),
 onPressed: () => Navigator.of(context).pop(),
 ),
 Expanded(
 child: Text(
 'Now Playing',
 textAlign: TextAlign.center,
 style: TextStyle(
 fontSize: 12,
 letterSpacing: 1.5,
 color: Colors.white.withValues(alpha: 0.8)),
 ),
 ),
 IconButton(
 icon: const Icon(Icons.queue_music,
 color: Colors.white, size: 24),
 onPressed: _openQueue,
 ),
 ]),
 Expanded(
 child: _lyricsOpen && _lyrics != null
 ? _LyricsView(
 lyrics: _lyrics!,
 onClose: () => setState(() => _lyricsOpen = false))
 : Center(
 child: Column(
 mainAxisAlignment: MainAxisAlignment.center,
 children: [
 // ARTWORK ~82% da largura com sombra
 Hero(
 tag: 'cover-${song.id}',
 child: Container(
 width: w * 0.82,
 height: w * 0.82,
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(20),
 boxShadow: [
 BoxShadow(
 color: Colors.black.withValues(alpha: 0.5),
 blurRadius: 40,
 offset: const Offset(0, 16),
 ),
 ],
 ),
 child: CoverArt(
 coverArtId: song.coverArt,
 size: w * 0.82,
 radius: 20),
 ),
 ),
 const SizedBox(height: 36),
 // METADATA à esquerda + like
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 28),
 child: Row(children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(song.title,
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: const TextStyle(
 fontSize: 22,
 fontWeight: FontWeight.w700,
 color: Colors.white)),
 const SizedBox(height: 4),
 GestureDetector(
 onTap: song.artistId.isNotEmpty
 ? () async {
 final artist = await app
 .subsonic!
 .getArtist(song.artistId);
 if (context.mounted) {
 Navigator.of(context)
 .pushNamed('/artist', arguments: artist);
 }
 }
 : null,
 child: Text(song.artist,
                               style: TextStyle(
                                   fontSize: 14,
                                   color: Colors.white.withValues(alpha: 0.7))),
                         ),
                         const SizedBox(height: 6),
                         StarRating(
                           rating: song.userRating,
                           size: 18,
                           activeColor: AppColors.primary,
                           inactiveColor: Colors.white.withValues(alpha: 0.3),
                           onRate: (newRating) async {
                             final client = app.subsonic;
                             if (client == null) return;
                             await client.setRating(song.id, newRating);
                             setState(() => song.userRating = newRating);
                           },
                         ),
                       ],
                     ),
                   ),
                   IconButton(
 icon: Icon(
 song.starred ? Icons.favorite : Icons.favorite_border,
 color:
 song.starred ? AppColors.primary : Colors.white,
 size: 26),
 onPressed: () async {
 final client = app.subsonic!;
 try {
 song.starred
 ? await client.unstar(song.id)
 : await client.star(song.id);
 setState(() => song.starred = !song.starred);
 } catch (_) {}
 },
 ),
 ]),
 ),
 ],
 ),
 ),
 ),
 // PROGRESSO com seek + tempos
 StreamBuilder<Duration>(
 stream: state!.player.positionStream,
 builder: (context, snap) {
 final pos = snap.data ?? Duration.zero;
 final total = Duration(seconds: song.duration);
 final maxSec = total.inSeconds <= 0 ? 1 : total.inSeconds;
 return Padding(
 padding: const EdgeInsets.symmetric(horizontal: 24),
 child: Column(children: [
 SliderTheme(
 data: SliderTheme.of(context).copyWith(
 trackHeight: 3,
 activeTrackColor: AppColors.primary,
 inactiveTrackColor:
 Colors.white.withValues(alpha: 0.25),
 thumbColor: AppColors.primary,
 overlayShape:
 const RoundSliderOverlayShape(overlayRadius: 14),
 ),
 child: Slider(
 value: pos.inSeconds.clamp(0, maxSec).toDouble(),
 max: maxSec.toDouble(),
 onChanged: (v) => state.player
 .seek(Duration(seconds: v.toInt())),
 ),
 ),
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 8),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text(_fmt(pos),
 style: TextStyle(
 fontSize: 11,
 color: Colors.white.withValues(alpha: 0.6))),
 Text(_fmt(total),
 style: TextStyle(
 fontSize: 11,
 color: Colors.white.withValues(alpha: 0.6))),
 ]),
 ),
 ]),
 );
 },
 ),
 const SizedBox(height: 8),
 // CONTROLES: shuffle | prev | PLAY (1.6x) | next | repeat
 Padding(
 padding: const EdgeInsets.only(bottom: 8),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
 children: [
 IconButton(
 icon: Icon(Icons.shuffle,
 color: state.isShuffled
 ? AppColors.primary
 : Colors.white.withValues(alpha: 0.7),
 size: 24),
 onPressed: () => state.toggleShuffle(),
 ),
 IconButton(
 icon: const Icon(Icons.skip_previous,
 color: Colors.white, size: 36),
 onPressed: () => state.skipToPrevious(),
 ),
 Container(
 width: 76,
 height: 76,
 decoration: BoxDecoration(
 color: AppColors.primary,
 shape: BoxShape.circle,
 boxShadow: [
 BoxShadow(
 color: AppColors.primary.withValues(alpha: 0.4),
 blurRadius: 24,
 spreadRadius: 2,
 ),
 ],
 ),
 child: IconButton(
 iconSize: 40,
 color: Colors.black,
 icon: Icon(state.player.playing
 ? Icons.pause
 : Icons.play_arrow),
 onPressed: () => state.player.playing
 ? state.pause()
 : state.play(),
 ),
 ),
 IconButton(
 icon: const Icon(Icons.skip_next,
 color: Colors.white, size: 36),
 onPressed: () => state.skipToNext(),
 ),
 StreamBuilder<AudioServiceRepeatMode>(
 stream:
 state.playbackState.map((s) => s.repeatMode).distinct(),
 builder: (_, snap) => IconButton(
 icon: Icon(Icons.repeat,
 color: snap.data == AudioServiceRepeatMode.none
 ? Colors.white.withValues(alpha: 0.7)
 : AppColors.primary,
 size: 24),
 onPressed: () => state.setRepeatMode(
 snap.data == AudioServiceRepeatMode.none
 ? AudioServiceRepeatMode.all
 : AudioServiceRepeatMode.none)),
 ),
 ],
 ),
 ),
 // AÇÕES inferiores: Fila | Letras | Timer | Speed
         Padding(
           padding: const EdgeInsets.only(bottom: 16),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               TextButton.icon(
                 onPressed: _openQueue,
                 icon: const Icon(Icons.queue_music,
                     color: Colors.white70, size: 20),
                 label: const Text('Fila',
                     style:
                         TextStyle(color: Colors.white70, fontSize: 12)),
               ),
               if (_lyrics != null) ...[
                 const SizedBox(width: 16),
                 TextButton.icon(
                   onPressed: () => setState(() => _lyricsOpen = true),
                   icon: const Icon(Icons.lyrics,
                       color: Colors.white70, size: 20),
                   label: const Text('Letras',
                       style:
                           TextStyle(color: Colors.white70, fontSize: 12)),
                 ),
               ],
               const SizedBox(width: 16),
               StreamBuilder<Duration?>(
                 stream: state.sleepRemainingStream,
                 builder: (_, snap) {
                   final remaining = snap.data;
                   final active = remaining != null;
                   return TextButton.icon(
                     onPressed: () => _showSleepTimerSheet(state),
                     icon: Icon(Icons.timer,
                         color: active
                             ? AppColors.primary
                             : Colors.white70,
                         size: 20),
                     label: Text(
                         active
                             ? '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}'
                             : 'Timer',
                         style: TextStyle(
                             color: active
                                 ? AppColors.primary
                                 : Colors.white70,
                             fontSize: 12)),
                   );
                 },
               ),
               const SizedBox(width: 16),
               TextButton.icon(
                 onPressed: () => _showSpeedSheet(state),
                 icon: const Icon(Icons.speed,
                     color: Colors.white70, size: 20),
                 label: Text('${state.playbackSpeed.toStringAsFixed(1)}x',
                     style: const TextStyle(
                         color: Colors.white70, fontSize: 12)),
               ),
             ],
           ),
         ),
 ]),
 ),
 ),
 ],
 ),
 );
 }

 String _fmt(Duration d) =>
 '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

/// Vista de letras com botão de fechar.
class _LyricsView extends StatelessWidget {
 final Lyrics lyrics;
 final VoidCallback onClose;
 const _LyricsView({required this.lyrics, required this.onClose});

 @override
 Widget build(BuildContext context) {
 return ListView(
 padding: const EdgeInsets.all(28),
 children: [
 Row(children: [
 IconButton(
 icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
 onPressed: onClose,
 ),
 Expanded(
 child: Text(lyrics.title,
 textAlign: TextAlign.center,
 style: const TextStyle(
 fontSize: 16,
 fontWeight: FontWeight.w700,
 color: Colors.white)),
 ),
 const SizedBox(width: 48),
 ]),
 const SizedBox(height: 16),
 Text(lyrics.text,
 style: TextStyle(
 fontSize: 16,
 height: 1.7,
 color: Colors.white.withValues(alpha: 0.85))),
 ],
 );
 }
}

/// Fila global (queue) — bottom sheet consumindo o PlayerHandler.
/// Ações reais: tocar faixa, remover da fila (removeAt), limpar.
class QueueSheet extends StatelessWidget {
 const QueueSheet({super.key});

 @override
 Widget build(BuildContext context) {
 final state = context.watch<AppState>().player;
 final queue = state?.songs ?? const <SubsonicSong>[];
 final current = state?.currentSong;

 return DraggableScrollableSheet(
 expand: false,
 initialChildSize: 0.75,
 maxChildSize: 0.92,
 builder: (context, scrollController) {
 final b = Theme.of(context).brightness;
 return Container(
 decoration: BoxDecoration(
 color: AppColors.surface(b),
 borderRadius:
 const BorderRadius.vertical(top: Radius.circular(20)),
 ),
 child: Column(children: [
 const SizedBox(height: 8),
 Container(
 width: 40,
 height: 4,
 decoration: BoxDecoration(
 color: AppColors.surface2(b),
 borderRadius: BorderRadius.circular(2)),
 ),
 Padding(
 padding: const EdgeInsets.all(16),
 child: Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text('Fila',
 style: TextStyle(
 fontSize: 18,
 fontWeight: FontWeight.w700,
 color: AppColors.textPrimary(b))),
 TextButton(
 onPressed: () async {
 await state?.stop();
 if (context.mounted) Navigator.of(context).pop();
 },
 child: const Text('Limpar',
 style: TextStyle(color: AppColors.danger))),
 ]),
 ),
 Expanded(
 child: queue.isEmpty
 ? const EmptyState(message: 'Fila vazia')
 : ListView.builder(
 controller: scrollController,
 itemCount: queue.length,
 itemBuilder: (_, i) {
 final s = queue[i];
 final isCurrent = s.id == current?.id;
 return ListTile(
 dense: true,
 onTap: () =>
 state?.playQueue(queue, startIndex: i),
 leading: isCurrent
 ? const Icon(Icons.graphic_eq,
 color: AppColors.primary)
 : CoverArt(
 coverArtId: s.coverArt, size: 44, radius: 8),
 title: Text(s.title,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w600,
 color: isCurrent
 ? AppColors.primary
 : AppColors.textPrimary(b))),
 subtitle: Text(s.artist,
 maxLines: 1,
 style: TextStyle(
 fontSize: 12,
 color: AppColors.textSecondary(b))),
 trailing: IconButton(
 icon: Icon(Icons.close,
 size: 20, color: AppColors.textSecondary(b)),
 onPressed: () => state?.removeAt(i),
 ),
 );
 },
 ),
 ),
 ],
 ),
 );
 },
 );
 }
}