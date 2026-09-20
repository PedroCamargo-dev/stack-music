import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/subsonic_client.dart';
import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Library / My music (refs 17.49.44 + 17.50.11): chips de filtro
/// (Playlists, Favoritos, Artistas, Álbuns, Rádios), Skeleton/Error/Empty
/// padronizados e rádio com stream REAL via just_audio.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum _LibTab { playlists, starred, artists, albums, radios }

class _LibraryScreenState extends State<LibraryScreen> {
  _LibTab tab = _LibTab.playlists;
  bool loading = true;
  String? error;

  List<SubsonicPlaylist> playlists = [];
  List<SubsonicSong> starred = [];
  List<SubsonicArtist> artists = [];
  List<SubsonicAlbum> albums = [];
  List<RadioStation> radios = [];
 List<SubsonicAlbum> continueList = [];

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
        client.getPlaylists(),
        client.getStarredSongs(),
        client.getArtists(),
        client.getAlbumList(type: 'alphabeticalByName', size: 50),
        client.getInternetRadioStations(),
      ]);
      setState(() {
        playlists = results[0] as List<SubsonicPlaylist>;
        starred = results[1] as List<SubsonicSong>;
        artists = results[2] as List<SubsonicArtist>;
        albums = results[3] as List<SubsonicAlbum>;
        radios = results[4] as List<RadioStation>;
 continueList = results[5] as List<SubsonicAlbum>;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  /// Rádio toca o streamUrl real no player (fim do SnackBar fake).
  void _playRadio(RadioStation r) {
    context.read<AppState>().player?.playUrl(r.streamUrl, title: r.name);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('My music',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: textP)),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: textS),
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/settings'),
                  ),
                ],
              ),
            ),
            // Chips de filtro (ref 17.50.11)
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
                          _LibTab.playlists =>
                            'Playlists (${playlists.length})',
                          _LibTab.starred =>
                            'Favoritos (${starred.length})',
                          _LibTab.artists =>
                            'Artistas (${artists.length})',
                          _LibTab.albums => 'Álbuns (${albums.length})',
                          _LibTab.radios => 'Rádios (${radios.length})',
                        }),
                        selected: tab == t,
                        onSelected: (_) => setState(() => tab = t),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const SkeletonList(count: 6)
                  : error != null
                      ? ErrorState(
                          message: 'Erro: $error', onRetry: _load)
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
      case _LibTab.playlists:
        if (playlists.isEmpty) {
          return _empty('Nenhuma playlist ainda');
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: playlists.length,
          itemBuilder: (_, i) {
            final pl = playlists[i];
            return ListTile(
              leading:
                  CoverArt(coverArtId: pl.coverArt, size: 52, radius: 12),
              title: Text(pl.name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textP)),
              subtitle: Text('${pl.songCount} faixas',
                  style: TextStyle(fontSize: 13, color: textS)),
              trailing: Icon(Icons.chevron_right, color: textS),
              onTap: () => Navigator.of(context)
                  .pushNamed('/playlist', arguments: pl),
            );
          },
        );
      case _LibTab.starred:
        if (starred.isEmpty) return _empty('Nenhum favorito ainda');
        return ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            for (final s in starred) TrackRow(song: s, queue: starred)
          ],
        );
      case _LibTab.artists:
        if (artists.isEmpty) return _empty('Nenhum artista ainda');
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: artists.length,
          itemBuilder: (_, i) {
            final a = artists[i];
            return ListTile(
              leading: ClipOval(
                  child: CoverArt(coverArtId: a.coverArt, size: 48, radius: 24)),
              title: Text(a.name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textP)),
              subtitle: Text('${a.albumCount ?? 0} álbuns',
                  style: TextStyle(fontSize: 13, color: textS)),
              trailing: Icon(Icons.chevron_right, color: textS),
              onTap: () =>
                  Navigator.of(context).pushNamed('/artist', arguments: a),
            );
          },
        );
      case _LibTab.radios:
        if (radios.isEmpty) {
          return _empty('Nenhuma rádio configurada no servidor');
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: radios.length,
          itemBuilder: (_, i) {
            final r = radios[i];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.radio)),
              title: Text(r.name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textP)),
              subtitle: Text(r.homepageUrl ?? r.streamUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: textS)),
              trailing: const Icon(Icons.play_arrow,
                  color: AppColors.primary),
              onTap: () => _playRadio(r),
            );
          },
        );
      case _LibTab.albums:
        if (albums.isEmpty) return _empty('Nenhum álbum ainda');
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: albums.length,
          itemBuilder: (_, i) {
            final a = albums[i];
            return ListTile(
              leading:
                  CoverArt(coverArtId: a.coverArt, size: 52, radius: 12),
              title: Text(a.name,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textP)),
              subtitle: Text(
                  '${a.artist}${a.year != null ? ' · ${a.year}' : ''}',
                  style: TextStyle(fontSize: 13, color: textS)),
              trailing: Icon(Icons.chevron_right, color: textS),
              onTap: () =>
                  Navigator.of(context).pushNamed('/album', arguments: a),
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