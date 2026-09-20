import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Tela de playlist (ref 17.48.51): header com capa grande arredondada,
/// rótulo "PLAYLIST" uppercase, lista com play/pause por item, faixa ativa
/// com barra de progresso na cor primary, botões Play all / Shuffle.
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
    final totalDuration =
        songs.fold<int>(0, (acc, s) => acc + s.duration);

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : error != null
              ? Center(child: Text('Erro: $error'))
              : CustomScrollView(
                  slivers: [
                    // Header com capa grande e título sobreposto (ref 17.48.51)
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
                            // Play all + Shuffle
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
                    // Lista de faixas
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) =>
                            _PlaylistSongTile(song: songs[i], queue: songs),
                        childCount: songs.length,
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// Tile estilo ref 17.48.51: ícone play/pause dentro de círculo no leading,
/// título bold, artista e duração, faixa ativa com barra de progresso.
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
        onTap: () =>
            state?.playQueue(queue, startIndex: queue.indexOf(song)),
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          // ícone play/pause circular (ref 17.48.51)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.primary : AppColors.surface2(b),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCurrent && state!.player.playing
                  ? Icons.pause
                  : Icons.play_arrow,
              size: 18,
              color: isCurrent ? Colors.black : AppColors.textSecondary(b),
            ),
          ),
          const SizedBox(width: 12),
          CoverArt(coverArtId: song.coverArt, size: 48, radius: 8),
        ]),
        title: Text(song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    isCurrent ? AppColors.primary : AppColors.textPrimary(b))),
        subtitle: Text(song.artist,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary(b))),
        trailing: Text(song.durationLabel,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary(b))),
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
                value: total.inSeconds == 0
                    ? 0
                    : pos.inSeconds / total.inSeconds,
                minHeight: 2,
                backgroundColor: AppColors.surface2(b),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
              ),
            );
          },
        ),
    ]);
  }
}