import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<SubsonicPlaylist> _playlists = [];
  List<SubsonicAlbum> _recentAlbums = [];
  bool _loadingPlaylists = true;
  bool _loadingRecent = true;
  String? _errorPlaylists;
  String? _errorRecent;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadPlaylists(), _loadRecent()]);
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _loadingPlaylists = true;
      _errorPlaylists = null;
    });
    try {
      final client = context.read<AppState>().subsonic;
      if (client == null) throw Exception('Not connected');
      final list = await client.getPlaylists();
      if (!mounted) return;
      setState(() {
        _playlists = list;
        _loadingPlaylists = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorPlaylists = e.toString();
        _loadingPlaylists = false;
      });
    }
  }

  Future<void> _loadRecent() async {
    setState(() {
      _loadingRecent = true;
      _errorRecent = null;
    });
    try {
      final client = context.read<AppState>().subsonic;
      if (client == null) throw Exception('Not connected');
      final list = await client.getAlbumList(type: 'recent', size: 10);
      if (!mounted) return;
      setState(() {
        _recentAlbums = list;
        _loadingRecent = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorRecent = e.toString();
        _loadingRecent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final b = Theme.of(context).brightness;
    final username = app.subsonic?.username ?? 'User';
    final serverUrl = app.subsonic?.baseUrl ?? '';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Header com avatar + info
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.surface2(b),
                        child: Text(
                          username.isNotEmpty
                              ? username[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(b),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              serverUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary(b),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.settings,
                            color: AppColors.textSecondary(b)),
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Quick sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickSectionCard(
                      icon: Icons.favorite,
                      label: 'Favorites',
                      color: AppColors.primary,
                      onTap: () =>
                          Navigator.of(context).pushNamed('/favorites'),
                    ),
                    _QuickSectionCard(
                      icon: Icons.download_outlined,
                      label: 'Downloads',
                      color: AppColors.secondaryAccent,
                      onTap: () {
                        // Downloads not yet supported
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Downloads coming soon'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _QuickSectionCard(
                      icon: Icons.settings,
                      label: 'Settings',
                      color: AppColors.surface2(b),
                      textColor: AppColors.textPrimary(b),
                      onTap: () =>
                          Navigator.of(context).pushNamed('/settings'),
                    ),
                  ],
                ),
              ),
            ),

            // Playlists rail
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Playlists',
                onShowAll: _playlists.length > 5
                    ? () => Navigator.of(context).pushNamed('/playlists')
                    : null,
              ),
            ),
            if (_loadingPlaylists)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SkeletonList(count: 3),
                ),
              )
            else if (_errorPlaylists != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ErrorState(
                      message: _errorPlaylists!, onRetry: _loadPlaylists),
                ),
              )
            else if (_playlists.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: EmptyState(
                    message: 'No playlists yet',
                    icon: Icons.queue_music_outlined,
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _playlists.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) =>
                        PlaylistCard(playlist: _playlists[i], width: 150),
                  ),
                ),
              ),

            // History (recent albums)
            SliverToBoxAdapter(
              child: SectionHeader(title: 'Recently Played'),
            ),
            if (_loadingRecent)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SkeletonList(count: 4),
                ),
              )
            else if (_errorRecent != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ErrorState(
                      message: _errorRecent!, onRetry: _loadRecent),
                ),
              )
            else if (_recentAlbums.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: EmptyState(
                    message: 'No recent history',
                    icon: Icons.history,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => AlbumCard(album: _recentAlbums[i]),
                    childCount: _recentAlbums.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickSectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _QuickSectionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: fg),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}