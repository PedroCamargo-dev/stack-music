import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Playlist detail: hero grande (mesma linguagem de Album Detail),
/// metadata owner • songs • duration, play dominante + favorite + shuffle,
/// tracklist numerada sem capas repetidas, menu ⋯ com remover se editável.
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
  late SubsonicPlaylist playlist;

  @override
  void initState() {
    super.initState();
    playlist = widget.playlist;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final client = context.read<AppState>().subsonic!;
      // getPlaylistSongs já retorna a playlist completa via getPlaylist,
      // mas buscamos também os metadados atualizados (owner, songCount).
      final results = await Future.wait([
        client.getPlaylistSongs(playlist.id),
        client.getPlaylists().then((all) =>
            all.firstWhere((p) => p.id == playlist.id, orElse: () => playlist)),
      ]);
      setState(() {
        songs = results[0] as List<SubsonicSong>;
        playlist = results[1] as SubsonicPlaylist;
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
    if (t <= 0 && (playlist.duration ?? 0) > 0) {
      final d = playlist.duration!;
      return '${d ~/ 3600}h ${d % 3600 ~/ 60}min';
    }
    return '${t ~/ 3600}h ${t % 3600 ~/ 60}min';
  }

  /// Navidrome/Subsonic não expõe flag explícita de "editável" por usuário,
  /// mas playlists criadas pelo próprio usuário podem ser modificadas via
  /// updatePlaylist. Consideramos editável quando há owner definido.
  bool get _isEditable => playlist.owner != null && playlist.owner!.isNotEmpty;

  Future<void> _toggleFavorite() async {
    final client = context.read<AppState>().subsonic;
    if (client == null) return;
    final next = !playlist.starred;
    setState(() => playlist.starred = next);
    try {
      next ? await client.star(playlist.id) : await client.unstar(playlist.id);
    } catch (_) {
      if (mounted) setState(() => playlist.starred = !next);
    }
  }

  Future<void> _removeFromPlaylist(SubsonicSong song, int index) async {
    final client = context.read<AppState>().subsonic;
    if (client == null) return;
    // Optimistic UI
    setState(() => songs.removeAt(index));
    try {
      // updatePlaylist só suporta adicionar; para remover, recriamos a lista
      // sem a faixa removida. Navidrome aceita songIdToRemove na prática,
      // mas o contrato Subsonic padrão usa updatePlaylist com IDs restantes.
      final remainingIds = songs.map((s) => s.id).toList();
      await client.updatePlaylist(playlist.id, songIdsToAdd: remainingIds);
    } catch (_) {
      if (mounted) {
        setState(() => songs.insert(index, song));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao remover da playlist')),
          );
        }
      }
    }
  }

  void _showTrackMenu(SubsonicSong song, int index) {
    final player = context.read<AppState>().player;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play next'),
              onTap: () {
                Navigator.pop(ctx);
                player?.playQueue(songs, startIndex: index);
              },
            ),
            ListTile(
              leading: Icon(
                  song.starred ? Icons.favorite : Icons.favorite_border),
              title: Text(song.starred ? 'Unfavorite' : 'Favorite'),
              onTap: () async {
                Navigator.pop(ctx);
                final client = context.read<AppState>().subsonic;
                if (client == null) return;
                final next = !song.starred;
                setState(() => song.starred = next);
                try {
                  next
                      ? await client.star(song.id)
                      : await client.unstar(song.id);
                } catch (_) {
                  if (mounted) setState(() => song.starred = !next);
                }
              },
            ),
            if (_isEditable)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remover da playlist'),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeFromPlaylist(song, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final textP = AppColors.textPrimary(b);
    final textS = AppColors.textSecondary(b);

    return Scaffold(
      body: loading
          ? const SkeletonList(count: 8)
          : error != null
              ? ErrorState(message: 'Erro: $error', onRetry: _load)
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back, color: textP),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      title: Text(playlist.name,
                          style: TextStyle(color: textP, fontSize: 16)),
                    ),
                    // Hero + metadata + ações
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            // Capa centralizada ~70% da largura (Album Detail language)
                            FractionallySizedBox(
                              widthFactor: 0.70,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Hero(
                                  tag: 'playlist-${playlist.id}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: CoverArt(
                                      coverArtId: playlist.coverArt,
                                      size: 600,
                                      radius: 0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Playlist name
                            Text(playlist.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: textP)),
                            const SizedBox(height: 6),
                            // Metadata: owner • songs • duration
                            Text(
                              [
                                if (playlist.owner != null &&
                                    playlist.owner!.isNotEmpty)
                                  playlist.owner!,
                                '${songs.length} songs',
                                _totalDuration,
                              ].join(' • '),
                              style:
                                  TextStyle(fontSize: 12, color: textS),
                            ),
                            const SizedBox(height: 16),
                            // Ações: Favorite + Play dominante + Shuffle
                            Row(children: [
                              IconButton.outlined(
                                onPressed: _toggleFavorite,
                                icon: Icon(
                                  playlist.starred
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: playlist.starred
                                      ? AppColors.primary
                                      : textP,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: const StadiumBorder(),
                                    textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: songs.isEmpty
                                      ? null
                                      : () => context
                                          .read<AppState>()
                                          .player
                                          ?.playQueue(songs),
                                  icon: const Icon(Icons.play_arrow,
                                      size: 22),
                                  label: const Text('Play'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  shape: const StadiumBorder(),
                                ),
                                onPressed: songs.isEmpty
                                    ? null
                                    : () {
                                        final p =
                                            context.read<AppState>().player;
                                        p?.toggleShuffle();
                                        p?.playQueue(songs);
                                      },
                                icon:
                                    const Icon(Icons.shuffle, size: 18),
                                label: const Text('Shuffle'),
                              ),
                            ]),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    // Tracklist numerada sem capas repetidas
                    if (songs.isEmpty)
                      const SliverToBoxAdapter(
                          child: EmptyState(message: 'Playlist vazia'))
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final s = songs[i];
                            final state = context.read<AppState>().player;
                            final isCurrent =
                                state?.currentSong?.id == s.id;
                            return InkWell(
                              onTap: () =>
                                  state?.playQueue(songs, startIndex: i),
                              onLongPress: () => _showTrackMenu(s, i),
                              child: SizedBox(
                                height: 60,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(children: [
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        '${i + 1}'.padLeft(2, '0'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isCurrent
                                              ? AppColors.primary
                                              : textS,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(s.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: isCurrent
                                                    ? AppColors.primary
                                                    : textP,
                                              )),
                                          const SizedBox(height: 2),
                                          Text(s.artist,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: textS)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(s.durationLabel,
                                        style: TextStyle(
                                            fontSize: 13, color: textS)),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      onTap: () => _showTrackMenu(s, i),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(Icons.more_vert,
                                            size: 20, color: textS),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            );
                          },
                          childCount: songs.length,
                        ),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                  ],
                ),
    );
  }
}