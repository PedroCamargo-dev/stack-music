import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<SubsonicSong> _songs = [];
  List<SubsonicAlbum> _albums = [];
  List<SubsonicArtist> _artists = [];

  bool _loadingSongs = true;
  bool _loadingAlbums = true;
  bool _loadingArtists = true;

  String? _errorSongs;
  String? _errorAlbums;
  String? _errorArtists;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadSongs(), _loadAlbums(), _loadArtists()]);
  }

  Future<void> _loadSongs() async {
    setState(() {
      _loadingSongs = true;
      _errorSongs = null;
    });
    try {
      final client = context.read<AppState>().subsonic;
      if (client == null) throw Exception('Not connected');
      final list = await client.getStarredSongs();
      if (!mounted) return;
      setState(() {
        _songs = list.where((s) => s.starred).toList();
        _loadingSongs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorSongs = e.toString();
        _loadingSongs = false;
      });
    }
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _loadingAlbums = true;
      _errorAlbums = null;
    });
    try {
      final client = context.read<AppState>().subsonic;
      if (client == null) throw Exception('Not connected');
      // getStarred2 also returns albums; using getAlbumList starred as fallback
      // Navidrome supports type='starred' in getAlbumList2
      final sub = await client.dio.getUri(
        client.buildUri('getAlbumList2', {'type': 'starred', 'size': '500'}),
      );
      final body = sub.data as Map<String, dynamic>;
      final resp = body['subsonic-response'] as Map<String, dynamic>;
      final list =
          ((resp['albumList2'] as Map<String, dynamic>)['album'] as List? ?? [])
              .cast<Map<String, dynamic>>()
              .map(SubsonicAlbum.fromJson)
              .where((a) => a.starred)
              .toList();
      if (!mounted) return;
      setState(() {
        _albums = list;
        _loadingAlbums = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorAlbums = e.toString();
        _loadingAlbums = false;
      });
    }
  }

  Future<void> _loadArtists() async {
    setState(() {
      _loadingArtists = true;
      _errorArtists = null;
    });
    try {
      final client = context.read<AppState>().subsonic;
      if (client == null) throw Exception('Not connected');
      final sub = await client.dio.getUri(
        client.buildUri('getStarred2'),
      );
      final body = sub.data as Map<String, dynamic>;
      final resp = body['subsonic-response'] as Map<String, dynamic>;
      final list =
          ((resp['starred2'] as Map<String, dynamic>)['artist'] as List? ?? [])
              .cast<Map<String, dynamic>>()
              .map(SubsonicArtist.fromJson)
              .toList();
      if (!mounted) return;
      setState(() {
        _artists = list;
        _loadingArtists = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorArtists = e.toString();
        _loadingArtists = false;
      });
    }
  }

  Future<void> _toggleStarSong(SubsonicSong song) async {
    final client = context.read<AppState>().subsonic;
    if (client == null) return;

    // Optimistic update
    setState(() {
      song.starred = !song.starred;
      if (!song.starred) _songs.removeWhere((s) => s.id == song.id);
    });

    try {
      if (song.starred) {
        await client.star(song.id);
      } else {
        await client.unstar(song.id);
      }
    } catch (_) {
      // Rollback
      if (mounted) {
        setState(() {
          song.starred = !song.starred;
          if (song.starred && !_songs.any((s) => s.id == song.id)) {
            _songs.add(song);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary(b),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSongsTab(b),
          _buildAlbumsTab(b),
          _buildArtistsTab(b),
        ],
      ),
    );
  }

  Widget _buildSongsTab(Brightness b) {
    if (_loadingSongs) return const SkeletonList(count: 8);
    if (_errorSongs != null) {
      return ErrorState(message: _errorSongs!, onRetry: _loadSongs);
    }
    if (_songs.isEmpty) {
      return const EmptyState(
        message: 'No favorite songs yet',
        icon: Icons.favorite_border,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSongs,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _songs.length,
        itemBuilder: (_, i) {
          final song = _songs[i];
          return TrackRow(
            song: song,
            queue: _songs,
            trailing: IconButton(
              icon: Icon(
                song.starred ? Icons.favorite : Icons.favorite_border,
                color: song.starred ? AppColors.primary : AppColors.textSecondary(b),
                size: 22,
              ),
              onPressed: () => _toggleStarSong(song),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumsTab(Brightness b) {
    if (_loadingAlbums) return const SkeletonList(count: 6);
    if (_errorAlbums != null) {
      return ErrorState(message: _errorAlbums!, onRetry: _loadAlbums);
    }
    if (_albums.isEmpty) {
      return const EmptyState(
        message: 'No favorite albums yet',
        icon: Icons.album_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAlbums,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _albums.length,
        itemBuilder: (_, i) => AlbumCard(album: _albums[i]),
      ),
    );
  }

  Widget _buildArtistsTab(Brightness b) {
    if (_loadingArtists) return const SkeletonList(count: 6);
    if (_errorArtists != null) {
      return ErrorState(message: _errorArtists!, onRetry: _loadArtists);
    }
    if (_artists.isEmpty) {
      return const EmptyState(
        message: 'No favorite artists yet',
        icon: Icons.person_outline,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadArtists,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _artists.length,
        itemBuilder: (_, i) => ArtistCard(artist: _artists[i], size: 90),
      ),
    );
  }
}