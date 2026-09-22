import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Library screen rebuilt per visual spec: pill filter chips, responsive grids
/// for albums/artists, larger playlist cards, recent list, standardized states.
/// "Downloaded" chip omitted — no offline cache support in library context.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum _LibTab { recent, playlists, albums, artists }

class _LibraryScreenState extends State<LibraryScreen> {
  _LibTab tab = _LibTab.recent;
  bool loading = true;
  String? error;

  List<SubsonicPlaylist> playlists = [];
  List<SubsonicSong> starred = [];
  List<SubsonicArtist> artists = [];
  List<SubsonicAlbum> albums = [];
  List<SubsonicAlbum> recentAlbums = [];

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
      final results = await Future.wait([
        client.getPlaylists(),
        client.getStarredSongs(),
        client.getArtists(),
        client.getAlbumList(type: 'alphabeticalByName', size: 50),
        client.getAlbumList(type: 'recent', size: 50),
      ]);
      setState(() {
        playlists = results[0] as List<SubsonicPlaylist>;
        starred = results[1] as List<SubsonicSong>;
        artists = results[2] as List<SubsonicArtist>;
        albums = results[3] as List<SubsonicAlbum>;
        recentAlbums = results[4] as List<SubsonicAlbum>;
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Library',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: textP,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: textS),
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/search'),
                  ),
                ],
              ),
            ),
            // FILTER CHIPS (pill style)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final t in _LibTab.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(switch (t) {
                          _LibTab.recent => 'Recent',
                          _LibTab.playlists => 'Playlists',
                          _LibTab.albums => 'Albums',
                          _LibTab.artists => 'Artists',
                        }),
                        selected: tab == t,
                        selectedColor: AppColors.primary,
                        onSelected: (_) => setState(() => tab = t),
                      ),
                    ),
                ],
              ),
            ),
            // CONTENT
            Expanded(
              child: loading
                  ? const SkeletonList(count: 6)
                  : error != null
                      ? ErrorState(message: 'Erro: $error', onRetry: _load)
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _load,
                          child: _buildTab(textP, textS, b),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(Color textP, Color textS, Brightness b) {
    switch (tab) {
      case _LibTab.recent:
        if (recentAlbums.isEmpty && starred.isEmpty) {
          return _empty('Nada recente ainda');
        }
        // Chronological list: recent albums first, then starred tracks
        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          children: [
            if (recentAlbums.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('Recent Albums',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textS)),
              ),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recentAlbums.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final a = recentAlbums[i];
                    return GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushNamed('/album', arguments: a),
                      child: SizedBox(
                        width: 140,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CoverArt(
                                coverArtId: a.coverArt,
                                size: 140,
                                radius: 12),
                            const SizedBox(height: 4),
                            Text(a.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textP)),
                            Text(a.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: textS)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (starred.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('Starred Tracks',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textS)),
              ),
              for (final s in starred) TrackRow(song: s, queue: starred),
            ],
          ],
        );

      case _LibTab.playlists:
        if (playlists.isEmpty) return _empty('Nenhuma playlist ainda');
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: playlists.length,
          itemBuilder: (_, i) {
            final pl = playlists[i];
            return GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed('/playlist', arguments: pl),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: CoverArt(
                          coverArtId: pl.coverArt, size: 200, radius: 0),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                      child: Text(pl.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textP)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: Text('${pl.songCount} faixas',
                          style: TextStyle(fontSize: 12, color: textS)),
                    ),
                  ],
                ),
              ),
            );
          },
        );

      case _LibTab.albums:
        if (albums.isEmpty) return _empty('Nenhum álbum ainda');
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: albums.length,
          itemBuilder: (_, i) {
            final a = albums[i];
            return GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed('/album', arguments: a),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoverArt(coverArtId: a.coverArt, size: 200, radius: 12),
                  const SizedBox(height: 6),
                  Text(a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textP)),
                  Text(a.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: textS)),
                ],
              ),
            );
          },
        );

      case _LibTab.artists:
        if (artists.isEmpty) return _empty('Nenhum artista ainda');
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: artists.length,
          itemBuilder: (_, i) {
            final a = artists[i];
            return GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed('/artist', arguments: a),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipOval(
                    child: CoverArt(
                        coverArtId: a.coverArt, size: 100, radius: 50),
                  ),
                  const SizedBox(height: 8),
                  Text(a.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textP)),
                  Text('${a.albumCount ?? 0} álbuns',
                      style: TextStyle(fontSize: 12, color: textS)),
                ],
              ),
            );
          },
        );
    }
  }

  Widget _empty(String msg) => ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(message: msg),
        ],
      );
}