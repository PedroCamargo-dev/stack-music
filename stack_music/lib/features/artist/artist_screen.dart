import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/subsonic_client.dart';
import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Artist Profile (ref 17.43.15): capa grande, stats, tabs ALBUMS | POPULAR.
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
 setState(() { loading = true; error = null; });
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
 setState(() { loading = false; error = e.toString(); });
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
 body: SafeArea(
 child: loading
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
 expandedHeight: 220,
 leading: IconButton(
 icon: Icon(Icons.arrow_back, color: textP),
 onPressed: () => Navigator.of(context).pop(),
 ),
 flexibleSpace: FlexibleSpaceBar(
 background: Stack(alignment: Alignment.bottomLeft, children: [
 SizedBox.expand(
 child: CoverArt(coverArtId: artist.coverArt, size: 600, radius: 0),
 ),
 // scrim para legibilidade
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
 Text(artist.name,
 style: TextStyle(
 fontSize: 26, fontWeight: FontWeight.w700, color: textP)),
 const SizedBox(height: 4),
 Text('${artist.albumCount ?? albums.length} ALBUMS',
 style: const TextStyle(fontSize: 11, letterSpacing: 1.2)),
 ],
 ),
 ),
 ]),
 ),
 bottom: TabBar(
 controller: _tabController,
 labelColor: textP,
 unselectedLabelColor: textS,
 indicatorColor: AppColors.primary,
 tabs: const [Tab(text: 'ALBUMS'), Tab(text: 'POPULAR'), Tab(text: 'ABOUT')],
 ),
 ),
 ],
 body: TabBarView(
 controller: _tabController,
 children: [
 // ALBUMS — grade 2 colunas
 GridView.builder(
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
 Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis,
 style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textP)),
 Text('${album.year ?? ''} · ${album.songCount} songs',
 style: TextStyle(fontSize: 12, color: textS)),
 ]),
 );
 },
 ),
 // ABOUT
 ListView(
 padding: const EdgeInsets.all(16),
 children: [
 if (info?.biography != null)
 Text(info!.biography!, style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary(b)))
 else
 Center(child: Text('Sem biografia (requer integracoes externas no servidor)',
 style: TextStyle(fontSize: 13, color: AppColors.textSecondary(b)))),
 ],
 ),
 // POPULAR
 topSongs.isEmpty
 ? Center(child: Text('Sem top songs (requer Last.fm no servidor)',
 style: TextStyle(fontSize: 13, color: textS)))
 : ListView(
 padding: const EdgeInsets.only(top: 8, bottom: 24),
 children: [for (final s in topSongs) SongTile(song: s, queue: topSongs)],
 ),
 ],
 ),
 ),
 ),
 );
 }
}