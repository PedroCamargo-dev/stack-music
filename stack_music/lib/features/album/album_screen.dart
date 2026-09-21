import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';
import '../artist/artist_screen.dart';

/// Album detail: capa centralizada grande (70% da largura), metadata abaixo,
/// play dominante + favorite, tracklist numerada sem capas repetidas.
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
  late SubsonicAlbum album;

  @override
  void initState() {
    super.initState();
    album = widget.album;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final client = context.read<AppState>().subsonic!;
      final results = await Future.wait([
        client.getSongsOfAlbum(widget.album.id),
        client.getAlbum(widget.album.id),
      ]);
      setState(() {
        songs = results[0] as List<SubsonicSong>;
        album = results[1] as SubsonicAlbum;
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
    if (t <= 0 && album.duration > 0) {
      final d = album.duration;
      return '${d ~/ 3600}h ${d % 3600 ~/ 60}min';
    }
    return '${t ~/ 3600}h ${t % 3600 ~/ 60}min';
  }

  Future<void> _toggleFavorite() async {
    final client = context.read<AppState>().subsonic;
    if (client == null) return;
    final next = !album.starred;
    setState(() => album.starred = next);
    try {
      next ? await client.star(album.id) : await client.unstar(album.id);
    } catch (_) {
      if (mounted) setState(() => album.starred = !next);
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
                      title: Text(album.name,
                          style: TextStyle(color: textP, fontSize: 16)),
                    ),
                    // Capa + metadata + ações
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            // Capa centralizada ~70% da largura
                            FractionallySizedBox(
                              widthFactor: 0.70,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Hero(
                                  tag: 'album-${album.id}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: CoverArt(
                                      coverArtId: album.coverArt,
                                      size: 600,
                                      radius: 0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Album name
                            Text(album.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: textP)),
                            const SizedBox(height: 6),
                            // Artist clicável
                            GestureDetector(
                              onTap: album.artistId.isNotEmpty
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ArtistScreen(
                                            artist: SubsonicArtist(
                                              id: album.artistId,
                                              name: album.artist,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Text(album.artist,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: album.artistId.isNotEmpty
                                        ? AppColors.primary
                                        : textS,
                                  )),
                            ),
                            const SizedBox(height: 6),
                            // Metadata discreta
                            Text(
                              [
                                if (album.year != null) '${album.year}',
                                '${album.songCount} songs',
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
                                  album.starred
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: album.starred
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
                                  onPressed: () => context
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
                                onPressed: () {
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
                    // Tracklist numerada
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
                                      '${s.track ?? i + 1}'.padLeft(2, '0'),
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