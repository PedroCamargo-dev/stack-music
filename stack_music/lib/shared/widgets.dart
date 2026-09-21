import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/models/subsonic_models.dart';
import '../core/theme/app_theme.dart';

// ============================================================
// Estados padronizados: Skeleton / Empty / Error
// ============================================================

/// Skeleton para carregamento de listas (linhas cinza pulsando).
class SkeletonList extends StatelessWidget {
 final int count;
 const SkeletonList({super.key, this.count = 6});

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 return ListView.builder(
 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
 itemCount: count,
 itemBuilder: (_, __) {
 return Padding(
 padding: const EdgeInsets.only(bottom: 12),
 child: Row(children: [
 Container(
 width: 48,
 height: 48,
 decoration: BoxDecoration(
 color: AppColors.surface2(b),
 borderRadius: BorderRadius.circular(8)),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Container(height: 14, decoration: BoxDecoration(
 color: AppColors.surface2(b),
 borderRadius: BorderRadius.circular(4))),
 const SizedBox(height: 6),
 Container(height: 10, width: 140, decoration: BoxDecoration(
 color: AppColors.surface2(b),
 borderRadius: BorderRadius.circular(4))),
 ]),
 ),
 ]),
 );
 },
 );
 }
}

/// Estado vazio padronizado por seção.
class EmptyState extends StatelessWidget {
 final String message;
 final IconData icon;
 const EmptyState({super.key, required this.message, this.icon = Icons.music_off});

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 return Center(
 child: Padding(
 padding: const EdgeInsets.all(32),
 child: Column(mainAxisSize: MainAxisSize.min, children: [
 Icon(icon, size: 40, color: AppColors.textSecondary(b)),
 const SizedBox(height: 12),
 Text(message, textAlign: TextAlign.center,
 style: TextStyle(fontSize: 14, color: AppColors.textSecondary(b))),
 ]),
 ),
 );
 }
}

/// Estado de erro padronizado com retry.
class ErrorState extends StatelessWidget {
 final String message;
 final VoidCallback onRetry;
 const ErrorState({super.key, required this.message, required this.onRetry});

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 return Center(
 child: Padding(
 padding: const EdgeInsets.all(32),
 child: Column(mainAxisSize: MainAxisSize.min, children: [
 const Icon(Icons.cloud_off, size: 40, color: AppColors.danger),
 const SizedBox(height: 12),
 Text(message, textAlign: TextAlign.center,
 style: TextStyle(fontSize: 14, color: AppColors.textSecondary(b))),
 const SizedBox(height: 16),
 FilledButton.icon(
 style: FilledButton.styleFrom(
 backgroundColor: AppColors.primary, foregroundColor: Colors.black),
 onPressed: onRetry,
 icon: const Icon(Icons.refresh),
 label: const Text('Tentar novamente')),
 ]),
 ),
 );
 }
}

// ============================================================
// Artwork
// ============================================================

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
 child: Icon(Icons.music_note,
 color: AppColors.textSecondary(Theme.of(context).brightness),
 size: size * 0.35),
 );
}

// ============================================================
// Cards padronizados (Ref 17.43.15 / 17.50.11)
// ============================================================

/// Card de álbum para carrosséis e grades.
class AlbumCard extends StatelessWidget {
 final SubsonicAlbum album;
 final double width;
 final VoidCallback? onPlay;
 const AlbumCard({super.key, required this.album, this.width = 160, this.onPlay});

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 return GestureDetector(
 onTap: () => Navigator.of(context).pushNamed('/album', arguments: album),
 child: SizedBox(
 width: width,
 child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 Stack(alignment: Alignment.center, children: [
 CoverArt(coverArtId: album.coverArt, size: width),
 if (onPlay != null)
 Positioned(
 right: 8, bottom: 8,
 child: GestureDetector(
 onTap: onPlay,
 child: Container(
 width: 40, height: 40,
 decoration: const BoxDecoration(
 color: AppColors.primary, shape: BoxShape.circle),
 child: const Icon(Icons.play_arrow, color: Colors.black, size: 24),
 ),
 ),
 ),
 ]),
 const SizedBox(height: 8),
 Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 13, fontWeight: FontWeight.w600,
 color: AppColors.textPrimary(b))),
 Text('${album.year ?? ''} · ${album.artist}',
 maxLines: 1, overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 12, color: AppColors.textSecondary(b))),
 ]),
 ),
 );
 }
}

/// Card de artista (círculo) para carrosséis.
class ArtistCard extends StatelessWidget {
 final SubsonicArtist artist;
 final double size;
 const ArtistCard({super.key, required this.artist, this.size = 80});

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 return GestureDetector(
 onTap: () => Navigator.of(context).pushNamed('/artist', arguments: artist),
 child: SizedBox(
 width: size + 10,
 child: Column(children: [
 ClipOval(child: CoverArt(coverArtId: artist.coverArt, size: size, radius: size / 2)),
 const SizedBox(height: 6),
 Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 12, color: AppColors.textPrimary(b))),
 ]),
 ),
 );
 }
}

/// Card de playlist para listas e carrosséis.
class PlaylistCard extends StatelessWidget {
 final SubsonicPlaylist playlist;
 final double width;
 const PlaylistCard({super.key, required this.playlist, this.width = 160});

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 return GestureDetector(
 onTap: () => Navigator.of(context).pushNamed('/playlist', arguments: playlist),
 child: SizedBox(
 width: width,
 child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 CoverArt(coverArtId: playlist.coverArt, size: width),
 const SizedBox(height: 8),
 Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 13, fontWeight: FontWeight.w600,
 color: AppColors.textPrimary(b))),
 Text('${playlist.songCount} faixas',
 style: TextStyle(
 fontSize: 12, color: AppColors.textSecondary(b))),
 ]),
 ),
 );
 }
}

// ============================================================
// TrackRow — linha de faixa unificada
// ============================================================

/// Linha de faixa unificada (substitui SongTile e _PlaylistSongTile).
/// Estrutura (ref 17.48.51): [cover] [título / artista • álbum] [duração] [...]
/// Tap no row → play; tap no artista → Artist Detail; menu → ações reais.
class TrackRow extends StatelessWidget {
 final SubsonicSong song;
 final List<SubsonicSong> queue;
 final int? index; // número opcional (tracklist numerada)
 final bool showIndex;
 final Widget? trailing;

 const TrackRow({
 super.key,
 required this.song,
 required this.queue,
 this.index,
 this.showIndex = false,
 this.trailing,
 });

 @override
 Widget build(BuildContext context) {
 final app = context.read<AppState>();
 final state = app.player;
 final b = Theme.of(context).brightness;
 final isCurrent = state?.currentSong?.id == song.id;

 return ListTile(
 onTap: () => state?.playQueue(queue,
 startIndex: showIndex && index != null ? index! : queue.indexOf(song)),
 dense: true,
 contentPadding: const EdgeInsets.symmetric(horizontal: 16),
 leading: Row(mainAxisSize: MainAxisSize.min, children: [
 if (showIndex && index != null)
 SizedBox(
 width: 26,
 child: Text('${index! + 1}',
 style: TextStyle(
 fontSize: 14,
 fontWeight: FontWeight.w700,
 color: isCurrent ? AppColors.primary : AppColors.textSecondary(b))),
 ),
 CoverArt(coverArtId: song.coverArt, size: 44, radius: 8),
 ]),
 title: Text(song.title,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 15,
 fontWeight: FontWeight.w600,
 color: isCurrent ? AppColors.primary : AppColors.textPrimary(b))),
 subtitle: Text(song.album.isNotEmpty ? '${song.artist} • ${song.album}' : song.artist,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: TextStyle(
 fontSize: 13, color: AppColors.textSecondary(b))),
 trailing: trailing ??
 Row(mainAxisSize: MainAxisSize.min, children: [
 if (isCurrent && state?.player.playing == true)
 const SizedBox(
 width: 16, height: 12,
 child: Icon(Icons.graphic_eq,
 size: 16, color: AppColors.primary)),
 Text(song.durationLabel,
 style: TextStyle(
 fontSize: 13, color: AppColors.textSecondary(b))),
 ]),
 );
 }
}

// ============================================================
// MiniPlayer — barra persistente elegante acima da BottomNav
// ============================================================

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>().player;
    final song = state?.currentSong;
    if (song == null) return const SizedBox.shrink();

    final b = Theme.of(context).brightness;
    final isPlaying = state!.player.playing;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/nowplaying'),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.surface2(b),
          border: Border(
            top: BorderSide(
              color: AppColors.textSecondary(b).withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar fina no topo (2px)
            StreamBuilder<Duration>(
              stream: state.player.positionStream,
              builder: (_, snap) {
                final pos = snap.data ?? Duration.zero;
                final total = Duration(seconds: song.duration);
                final progress =
                    total.inSeconds == 0 ? 0.0 : pos.inMilliseconds / total.inMilliseconds;
                return SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.textSecondary(b).withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 2,
                  ),
                );
              },
            ),
            // Corpo do mini player
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  // Cover art
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/nowplaying'),
                    child: CoverArt(coverArtId: song.coverArt, size: 48, radius: 8),
                  ),
                  const SizedBox(width: 12),
                  // Track info
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/nowplaying'),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(b),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary(b),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Play/Pause button
                  _MiniPlayerBtn(
                    icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    brightness: b,
                    onTap: () => isPlaying ? state.pause() : state.play(),
                  ),
                  const SizedBox(width: 2),
                  // Next button
                  _MiniPlayerBtn(
                    icon: Icons.skip_next_rounded,
                    brightness: b,
                    onTap: () => state.skipToNext(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayerBtn extends StatelessWidget {
  final IconData icon;
  final Brightness brightness;
  final VoidCallback onTap;

  const _MiniPlayerBtn({
    required this.icon,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: AppColors.textPrimary(brightness),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SectionHeader com "See all" (ref 17.50.11)
// ============================================================

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
 Text(title,
 style: TextStyle(
 fontSize: 18,
 fontWeight: FontWeight.w700,
 color: AppColors.textPrimary(b))),
 if (onShowAll != null)
 GestureDetector(
 onTap: onShowAll,
 child: Row(children: [
 Text('See all',
 style: TextStyle(
 fontSize: 13, color: AppColors.secondaryAccent)),
 Icon(Icons.chevron_right,
 size: 16, color: AppColors.secondaryAccent),
 ]),
 ),
 ],
 ),
 );
 }
}