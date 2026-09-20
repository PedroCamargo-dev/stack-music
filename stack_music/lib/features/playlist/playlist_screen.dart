import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Tela de playlist (ref 17.48.51): header com capa grande imersiva,
/// rótulo "PLAYLIST" uppercase, duração total, Play all/Shuffle em pílula,
/// faixas com TrackRow unificado + barra de progresso na faixa ativa.
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
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final s = await context
          .read<AppState>()
          .subsonic!
          .getPlaylistSongs(widget.playlist.id);
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

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final textP = AppColors.textPrimary(b);
    final textS = AppColors.textSecondary(b);
    final player = context.watch<AppState>().player;
    final totalDuration = songs.fold<int>(0, (acc, s) => acc + s.duration);

    return Scaffold(
      body: loading
          ? const Scaffold(body: SkeletonList(count: 6))
          : error != null
              ? ErrorState(message: 'Erro: $error', onRetry: _load)
              : CustomScrollView(
                  slivers: [
                    // Header com capa grande (ref 17.48.51)
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 300,
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back, color: textP),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            CoverArt(
                                coverArtId: widget.playlist.coverArt,
                                size: 600,
                                radius: 0),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Info + ações
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PLAYLIST',
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                    color: textS)),
                            const SizedBox(height: 4),
                            Text(widget.playlist.name,
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: textP)),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.playlist.songCount} faixas · '
                              '${totalDuration ~/ 3600}h ${totalDuration % 3600 ~/ 60}min'
                              '${widget.playlist.owner != null ? ' · ${widget.playlist.owner}' : ''}',
                              style:
                                  TextStyle(fontSize: 12, color: textS),
                            ),
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
                                onPressed: () =>
                                    player?.playQueue(songs),
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
                                  player?.toggleShuffle();
                                  player?.playQueue(songs);
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
                    // Faixas: TrackRow unificado + progresso na ativa
                    if (songs.isEmpty)
                      const SliverToBoxAdapter(
                          child: EmptyState(message: 'Playlist vazia'))
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _PlaylistRow(song: songs[i], queue: songs),
                          childCount: songs.length,
                        ),
                      ),
                  ],
                ),
    );
  }
}

/// TrackRow com barra de progresso embutida na faixa ativa (ref 17.48.51).
class _PlaylistRow extends StatelessWidget {
  final SubsonicSong song;
  final List<SubsonicSong> queue;
  const _PlaylistRow({required this.song, required this.queue});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>().player;
    final isCurrent = state?.currentSong?.id == song.id;

    return Column(children: [
      TrackRow(song: song, queue: queue, index: queue.indexOf(song)),
      if (isCurrent)
        StreamBuilder<Duration>(
          stream: state!.player.positionStream,
          builder: (_, snap) {
            final pos = snap.data ?? Duration.zero;
            final total = Duration(seconds: song.duration);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LinearProgressIndicator(
                value: total.inSeconds == 0
                    ? 0
                    : pos.inSeconds / total.inSeconds,
                minHeight: 2,
                backgroundColor: AppColors.surface2(
                    Theme.of(context).brightness),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
              ),
            );
          },
        ),
    ]);
  }
}