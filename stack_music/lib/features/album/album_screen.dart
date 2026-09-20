import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Tela de álbum (refs 17.43.15 + 17.48.51): capa grande imersiva com scrim,
/// título/artist sobre a capa, Play all em pílula, faixas numeradas.
class AlbumScreen extends StatefulWidget {
  final SubsonicAlbum album;
  const AlbumScreen({super.key, required this.album});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<SubsonicSong> songs = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final s = await context
          .read<AppState>()
          .subsonic!
          .getSongsOfAlbum(widget.album.id);
      setState(() {
        songs = s;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  String get _totalDuration {
    final t = songs.fold<int>(0, (acc, s) => acc + s.duration);
    return '${t ~/ 3600}h ${t % 3600 ~/ 60}min';
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final textP = AppColors.textPrimary(b);
    final textS = AppColors.textSecondary(b);
    final album = widget.album;

    return Scaffold(
      body: loading
          ? const Scaffold(body: SkeletonList(count: 6))
          : error != null
              ? ErrorState(message: 'Erro: $error', onRetry: _load)
              : CustomScrollView(
                  slivers: [
                    // Capa grande imersiva (ref 17.48.51)
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 320,
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back, color: textP),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'album-${album.id}',
                              child: CoverArt(
                                  coverArtId: album.coverArt,
                                  size: 600,
                                  radius: 0),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Theme.of(context).scaffoldBackgroundColor,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Metadados + ações
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ÁLBUM',
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                    color: textS)),
                            const SizedBox(height: 4),
                            Text(album.name,
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: textP)),
                            const SizedBox(height: 4),
                            Text(
                              '${album.artist} · ${album.year ?? ''}'
                              '${album.genre != null ? ' · ${album.genre}' : ''}',
                              style: TextStyle(fontSize: 13, color: textS),
                            ),
                            const SizedBox(height: 4),
                            Text('${album.songCount} faixas · $_totalDuration',
                                style: TextStyle(
                                    fontSize: 12, color: textS)),
                            const SizedBox(height: 16),
                            Row(children: [
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: () => context
                                    .read<AppState>()
                                    .player
                                    ?.playQueue(songs),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Play all'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: () {
                                  final p =
                                      context.read<AppState>().player;
                                  p?.toggleShuffle();
                                  p?.playQueue(songs);
                                },
                                icon: const Icon(Icons.shuffle, size: 18),
                                label: const Text('Shuffle'),
                              ),
                            ]),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    // Faixas numeradas (estilo tracklist)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final s = songs[i];
                          final state = context.read<AppState>().player;
                          final isCurrent =
                              state?.currentSong?.id == s.id;
                          return ListTile(
                            onTap: () => state?.playQueue(songs,
                                startIndex: i),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                      '${s.track ?? i + 1}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isCurrent
                                              ? AppColors.primary
                                              : textS)),
                                ),
                                CoverArt(
                                    coverArtId: s.coverArt,
                                    size: 48,
                                    radius: 8),
                              ],
                            ),
                            title: Text(s.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isCurrent
                                        ? AppColors.primary
                                        : textP)),
                            subtitle: Text(s.artist,
                                style: TextStyle(
                                    fontSize: 13, color: textS)),
                            trailing: Text(s.durationLabel,
                                style: TextStyle(
                                    fontSize: 13, color: textS)),
                          );
                        },
                        childCount: songs.length,
                      ),
                    ),
                  ],
                ),
    );
  }
}