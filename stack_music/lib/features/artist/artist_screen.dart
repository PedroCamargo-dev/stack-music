import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/subsonic_client.dart';
import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Artist Profile (refs 17.43.15 + 17.50.11): capa grande com scrim,
/// badge verificado, stats em uppercase, tabs ÁLBUNS | POPULAR | SOBRE.
class ArtistScreen extends StatefulWidget {
  final SubsonicArtist artist;
  const ArtistScreen({super.key, required this.artist});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<SubsonicAlbum> albums = [];
  List<SubsonicSong> topSongs = [];
  ArtistInfo? info;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final textP = AppColors.textPrimary(b);
    final textS = AppColors.textSecondary(b);
    final artist = widget.artist;

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Erro: $error'),
                  TextButton(onPressed: _load, child: const Text('Tentar novamente')),
                ]))
              : NestedScrollView(
                  headerSliverBuilder: (_, __) => [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 260,
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back, color: textP),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            SizedBox.expand(
                              child: CoverArt(
                                  coverArtId: artist.coverArt, size: 600, radius: 0),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Theme.of(context).scaffoldBackgroundColor,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(artist.name,
                                        style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: textP)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified,
                                        color: AppColors.primary, size: 20),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${albums.length} ÁLBUNS · ${topSongs.length} TOP SONGS',
                                    style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 1.5,
                                        color: textS),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      bottom: TabBar(
                        controller: _tabController,
                        labelColor: textP,
                        unselectedLabelColor: textS,
                        indicatorColor: AppColors.primary,
                        tabs: const [
                          Tab(text: 'ÁLBUNS'),
                          Tab(text: 'POPULAR'),
                          Tab(text: 'SOBRE'),
                        ],
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      // ÁLBUNS — grade 2 colunas
                      albums.isEmpty
                          ? Center(child: Text('Nenhum álbum', style: TextStyle(fontSize: 13, color: textS)))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16),
                              itemCount: albums.length,
                              itemBuilder: (_, i) {
                                final album = albums[i];
                                return GestureDetector(
                                  onTap: () => Navigator.of(context).pushNamed('/album', arguments: album),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(child: CoverArt(coverArtId: album.coverArt, size: 160)),
                                    const SizedBox(height: 6),
                                    Text(album.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textP)),
                                    Text('${album.year ?? ''} · ${album.songCount} faixas',
                                        style: TextStyle(fontSize: 12, color: textS)),
                                  ]),
                                );
                              },
                            ),
                      // POPULAR — lista numerada estilo MusicBox
                      topSongs.isEmpty
                          ? Center(child: Text('Sem top songs (requer Last.fm no servidor)', style: TextStyle(fontSize: 13, color: textS)))
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 8, bottom: 24),
                              itemCount: topSongs.length,
                              itemBuilder: (_, i) {
                                final s = topSongs[i];
                                return ListTile(
                                  onTap: () => context.read<AppState>().player?.playQueue(topSongs, startIndex: i),
                                  leading: Row(mainAxisSize: MainAxisSize.min, children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text('${i + 1}',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textS)),
                                    ),
                                    CoverArt(coverArtId: s.coverArt, size: 48, radius: 8),
                                  ]),
                                  title: Text(s.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textP)),
                                  subtitle: Text('${s.playCount ?? 0} plays · ${s.album}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, color: textS)),
                                  trailing: Text(s.durationLabel, style: TextStyle(fontSize: 13, color: textS)),
                                );
                              },
                            ),
                      // SOBRE — biografia
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (info?.biography != null && info!.biography!.isNotEmpty)
                            Text(info!.biography!,
                                style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary(b)))
                          else
                            Center(child: Text('Sem biografia (requer integrações externas no servidor)',
                                style: TextStyle(fontSize: 13, color: textS))),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}