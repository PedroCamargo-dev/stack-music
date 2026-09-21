import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Home reconstruída: header compacto, artist rail circular, hero landscape
/// 1.6:1 com scrim + play flutuante, recently played, new releases,
/// top songs em lista compacta de TrackRows, mini player persistente.
/// Seções vazias não renderizam. Dados reais via Subsonic/Navidrome.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SubsonicArtist> artists = [];
  SubsonicAlbum? heroAlbum;
  List<SubsonicAlbum> recent = [];
  List<SubsonicAlbum> newest = [];
  List<SubsonicSong> topSongs = [];
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
    final client = context.read<AppState>().subsonic;
    if (client == null) {
      setState(() {
        loading = false;
        error = 'Servidor não conectado';
      });
      return;
    }
    try {
      debugPrint('[HOME] _load iniciando chamadas...');
      final t0 = DateTime.now();
      final results = await Future.wait([
        client.getArtists().then((v) { debugPrint('[HOME] getArtists OK (${DateTime.now().difference(t0).inMilliseconds}ms)'); return v; }),
        client.getAlbumList(type: 'frequent', size: 1).then((v) { debugPrint('[HOME] getAlbumList(frequent) OK (${DateTime.now().difference(t0).inMilliseconds}ms)'); return v; }),
        client.getAlbumList(type: 'recent', size: 10).then((v) { debugPrint('[HOME] getAlbumList(recent) OK (${DateTime.now().difference(t0).inMilliseconds}ms)'); return v; }),
        client.getAlbumList(type: 'newest', size: 10).then((v) { debugPrint('[HOME] getAlbumList(newest) OK (${DateTime.now().difference(t0).inMilliseconds}ms)'); return v; }),
        client.getRandomSongs(size: 10).then((v) { debugPrint('[HOME] getRandomSongs OK (${DateTime.now().difference(t0).inMilliseconds}ms)'); return v; }),
      ]);
      debugPrint('[HOME] Future.wait completo, aplicando setState...');
      setState(() {
        artists = results[0] as List<SubsonicArtist>;
        final heroList = results[1] as List<SubsonicAlbum>;
        heroAlbum = heroList.isNotEmpty ? heroList.first : null;
        recent = results[2] as List<SubsonicAlbum>;
        newest = results[3] as List<SubsonicAlbum>;
        topSongs = results[4] as List<SubsonicSong>;
        loading = false;
      });
      debugPrint('[HOME] setState aplicado, loading=false');
    } catch (e) {
      debugPrint('[HOME] _load ERRO: $e');
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _playAlbum(SubsonicAlbum album) async {
    final app = context.read<AppState>();
    try {
      final songs = await app.subsonic!.getSongsOfAlbum(album.id);
      if (songs.isNotEmpty && mounted) app.player?.playQueue(songs);
    } catch (_) {}
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().subsonic?.username ?? '';

    if (loading) {
      return const Scaffold(body: SkeletonList(count: 8));
    }
    if (error != null) {
      return Scaffold(
        body: ErrorState(message: 'Erro ao carregar: $error', onRetry: _load),
      );
    }

    final hasContent = artists.isNotEmpty ||
        heroAlbum != null ||
        recent.isNotEmpty ||
        newest.isNotEmpty ||
        topSongs.isNotEmpty;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            // 1. HEADER COMPACTO (max 64px)
            _CompactHeader(
              greeting: _greeting,
              username: user,
              onSearch: () => Navigator.of(context).pushNamed('/search'),
              onAvatar: () => Navigator.of(context).pushNamed('/settings'),
            ),

            // 2. POPULAR ARTISTS RAIL
            if (artists.isNotEmpty) ...[
              const SectionHeader(title: 'Popular Artists'),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: artists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) =>
                      ArtistCard(artist: artists[i], size: 86),
                ),
              ),
            ],

            // 3. DISCOVER HERO (landscape 1.6:1)
            if (heroAlbum != null) ...[
              const SectionHeader(title: 'Discover'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DiscoverHero(
                  album: heroAlbum!,
                  onPlay: () => _playAlbum(heroAlbum!),
                ),
              ),
            ],

            // 4. RECENTLY PLAYED
            if (recent.isNotEmpty) ...[
              const SectionHeader(title: 'Recently Played'),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => AlbumCard(
                    album: recent[i],
                    width: 150,
                    onPlay: () => _playAlbum(recent[i]),
                  ),
                ),
              ),
            ],

            // 5. NEW RELEASES
            if (newest.isNotEmpty) ...[
              const SectionHeader(title: 'New Releases'),
              SizedBox(
                height: 195,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: newest.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => AlbumCard(
                    album: newest[i],
                    width: 130,
                    onPlay: () => _playAlbum(newest[i]),
                  ),
                ),
              ),
            ],

            // 6. TOP SONGS LISTA (TrackRows compactos)
            if (topSongs.isNotEmpty) ...[
              const SectionHeader(title: 'Top Songs'),
              ...topSongs.map((s) => TrackRow(song: s, queue: topSongs)),
            ],

            // Empty state global
            if (!hasContent)
              const EmptyState(
                  message: 'Nada encontrado no servidor Navidrome'),
          ],
        ),
      ),
      // 7. MINI PLAYER persistente acima da bottom nav
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

// ============================================================
// Header compacto: saudação + 'Music' esquerda; busca + avatar direita
// ============================================================

class _CompactHeader extends StatelessWidget {
  final String greeting;
  final String username;
  final VoidCallback onSearch;
  final VoidCallback onAvatar;

  const _CompactHeader({
    required this.greeting,
    required this.username,
    required this.onSearch,
    required this.onAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final textP = AppColors.textPrimary(b);
    final textS = AppColors.textSecondary(b);

    return Container(
      constraints: const BoxConstraints(maxHeight: 64),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(greeting,
                    style: TextStyle(fontSize: 13, color: textS)),
                Text('Music',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textP)),
              ],
            ),
          ),
          IconButton(
            onPressed: onSearch,
            icon: Icon(Icons.search, color: textP),
            splashRadius: 20,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onAvatar,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ============================================================
// Discover Hero: card landscape 1.6:1, artwork edge-to-edge,
// texto sobre imagem com gradient scrim, play flutuante
// ============================================================

class _DiscoverHero extends StatelessWidget {
  final SubsonicAlbum album;
  final VoidCallback onPlay;

  const _DiscoverHero({required this.album, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final url =
        app.subsonic?.coverArtUrl(album.coverArt, size: 800) ?? '';
    final b = Theme.of(context).brightness;

    return AspectRatio(
      aspectRatio: 1.6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Artwork edge-to-edge
            if (url.isNotEmpty)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    _heroPlaceholder(b),
                errorWidget: (_, __, ___) =>
                    _heroPlaceholder(b),
              )
            else
              _heroPlaceholder(b),

            // Gradient scrim para leitura
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),

            // Texto sobre a imagem
            Positioned(
              left: 16,
              right: 72,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(album.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(album.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),

            // Botão PLAY flutuante canto inferior direito
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: onPlay,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.black, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPlaceholder(Brightness b) => Container(
        color: AppColors.surface2(b),
        child: Center(
          child: Icon(Icons.music_note,
              size: 48, color: AppColors.textSecondary(b)),
        ),
      );
}