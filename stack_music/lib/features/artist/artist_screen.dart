import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/subsonic_client.dart';
import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Artist Detail — RECONSTRUÇÃO VISUAL:
/// - hero gigante edge-to-edge (35-45% da altura), nome SOBRE a foto;
/// - gradient forte na base da foto conectando ao conteúdo;
/// - Play dominante + Shuffle logo abaixo do hero;
/// - Popular Songs em rows compactas;
/// - Discografia em rail horizontal (não grid);
/// - SOBRE/biografia real do getArtistInfo2 ao final.
class ArtistScreen extends StatefulWidget {
  final SubsonicArtist artist;
  const ArtistScreen({super.key, required this.artist});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  List<SubsonicAlbum> albums = [];
  List<SubsonicSong> topSongs = [];
  ArtistInfo? info;
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
    final client = context.read<AppState>().subsonic!;
    try {
      final results = await Future.wait([
        client.getAlbumsOfArtist(widget.artist.id),
        client.getTopSongs(widget.artist.name, count: 15),
        client.getArtistInfo(widget.artist.id),
      ]);
      setState(() {
        albums = results[0] as List<SubsonicAlbum>;
        topSongs = results[1] as List<SubsonicSong>;
        info = results[2] as ArtistInfo?;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  void _playAll() {
    if (topSongs.isNotEmpty) {
      context.read<AppState>().player?.playQueue(topSongs);
    }
  }

  void _shuffleAll() {
    final p = context.read<AppState>().player;
    if (topSongs.isNotEmpty) {
      p?.toggleShuffle();
      p?.playQueue(topSongs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final textP = AppColors.textPrimary(b);
    final textS = AppColors.textSecondary(b);
    final artist = widget.artist;
    final screenH = MediaQuery.of(context).size.height;

    if (loading) {
      return const Scaffold(body: SkeletonList(count: 6));
    }
    if (error != null) {
      return Scaffold(
          body: ErrorState(message: 'Erro: $error', onRetry: _load));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // HERO — 40% da altura, edge-to-edge, nome sobre a foto
          SliverAppBar(
            pinned: true,
            expandedHeight: screenH * 0.40,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CoverArt(
                      coverArtId: artist.coverArt, size: 800, radius: 0),
                  // gradient forte conectando a foto ao conteúdo
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.45, 1.0],
                        colors: [
                          Theme.of(context).scaffoldBackgroundColor,
                          Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // nome SOBRE a imagem, na base
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(artist.name,
                              style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: textP)),
                          const SizedBox(height: 4),
                          Text(
                            '${albums.length} álbuns'
                            '${topSongs.isNotEmpty ? ' · ${topSongs.length} top songs' : ''}',
                            style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 1.2,
                                color: textS),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // AÇÕES: Play dominante + Shuffle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textP,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _shuffleAll,
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text('Shuffle'),
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _playAll,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('PLAY'),
                ),
              ]),
            ),
          ),
          // POPULAR SONGS — rows compactas
          if (topSongs.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Popular Songs',
                onShowAll: () {
                  // TODO: navegar para lista completa de músicas do artista
                },
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => TrackRow(song: topSongs[i], queue: topSongs, index: i),
                childCount: topSongs.length,
              ),
            ),
          ],
          // DISCOGRAPHY — rail horizontal
          if (albums.isNotEmpty) ...[
            const SliverToBoxAdapter(
                child: SectionHeader(title: 'Discografia')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: albums.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => AlbumCard(
                    album: albums[i],
                    width: 160,
                    onPlay: () async {
                      final app = context.read<AppState>();
                      try {
                        final songs =
                            await app.subsonic!.getSongsOfAlbum(albums[i].id);
                        if (songs.isNotEmpty) {
                          app.player?.playQueue(songs);
                        }
                      } catch (_) {}
                    },
                  ),
                ),
              ),
            ),
          ],
          // SOBRE — biografia real
          if (info?.biography != null && info!.biography!.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader(title: 'Sobre')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text(info!.biography!,
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textSecondary(b))),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}