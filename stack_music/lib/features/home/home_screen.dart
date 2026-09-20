import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Home (refs 17.50.11 + 17.43.15): header com saudação + avatar,
/// módulos que somem quando vazios, carrosséis padronizados, TrackRow.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SubsonicAlbum> newest = [];
  List<SubsonicAlbum> frequent = [];
  List<SubsonicArtist> artists = [];
  List<SubsonicSong> random = [];
  List<SubsonicSong> nowPlayingList = [];
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
        client.getAlbumList(type: 'newest', size: 10),
        client.getAlbumList(type: 'frequent', size: 10),
        client.getArtists(),
        client.getRandomSongs(size: 10),
        client.getNowPlaying(),
      ]);
      setState(() {
        newest = results[0] as List<SubsonicAlbum>;
        frequent = results[1] as List<SubsonicAlbum>;
        artists = results[2] as List<SubsonicArtist>;
        random = results[3] as List<SubsonicSong>;
        nowPlayingList = results[4] as List<SubsonicSong>;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final textP = AppColors.textPrimary(b);
    final user = context.watch<AppState>().subsonic?.username ?? '';

    if (loading) {
      return const Scaffold(body: SkeletonList(count: 8));
    }
    if (error != null) {
      return Scaffold(
        body: ErrorState(message: 'Erro ao carregar: $error', onRetry: _load),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // Header (ref 17.50.11): saudação + avatar de perfil
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary(b))),
                      Text('Home',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: textP)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.isNotEmpty ? user[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ]),
            ),

            // Tocando agora (getNowPlaying) — some se vazia
            if (nowPlayingList.isNotEmpty) ...[
              const SectionHeader(title: 'Tocando agora'),
              ...nowPlayingList
                  .take(5)
                  .map((s) => TrackRow(song: s, queue: nowPlayingList)),
            ],

            // Just for you — hero (ref 17.43.15)
            if (newest.isNotEmpty) ...[
              const SectionHeader(title: 'Just for you'),
              SizedBox(
                height: 215,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: newest.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => AlbumCard(album: newest[i], width: 170),
                ),
              ),
            ],

            // Trending today — mais tocados (ref 17.50.11)
            if (frequent.isNotEmpty) ...[
              const SectionHeader(title: 'Trending today'),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: frequent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => AlbumCard(album: frequent[i], width: 140),
                ),
              ),
            ],

            // Top artists — círculos (ref 17.50.11)
            if (artists.isNotEmpty) ...[
              const SectionHeader(title: 'Top artists'),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: artists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ArtistCard(artist: artists[i], size: 76),
                ),
              ),
            ],

            // Picked for you — músicas aleatórias
            if (random.isNotEmpty) ...[
              const SectionHeader(title: 'Picked for you'),
              ...random.take(5).map((s) => TrackRow(song: s, queue: random)),
            ],

            // Biblioteca vazia
            if (newest.isEmpty &&
                frequent.isEmpty &&
                artists.isEmpty &&
                random.isEmpty)
              const EmptyState(message: 'Nada encontrado no servidor Navidrome'),
          ],
        ),
      ),
    );
  }
}