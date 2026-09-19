import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/models/subsonic_models.dart';
import '../core/theme/app_theme.dart';
import '../shared/widgets.dart';

/// Home (refs 17.50.11 + 17.43.15): hero "Just for you", carrosséis
/// Trending today / Top artists / New releases, com "Show all".
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
 bool loading = true;
 String? error;

 @override
 void initState() {
 super.initState();
 _load();
 }

 Future<void> _load() async {
 setState(() { loading = true; error = null; });
 final client = context.read<AppState>().subsonic!;
 try {
 final results = await Future.wait([
 client.getAlbumList(type: 'newest', size: 10),
 client.getAlbumList(type: 'frequent', size: 10),
 client.getArtists(),
 client.getRandomSongs(size: 10),
 ]);
 setState(() {
 newest = results[0] as List<SubsonicAlbum>;
 frequent = results[1] as List<SubsonicAlbum>;
 artists = results[2] as List<SubsonicArtist>;
 random = results[3] as List<SubsonicSong>;
 loading = false;
 });
 } catch (e) {
 setState(() { loading = false; error = e.toString(); });
 }
 }

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 final textP = AppColors.textPrimary(b);

 if (loading) {
 return const Center(child: CircularProgressIndicator(color: AppColors.primary));
 }
 if (error != null) {
 return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
 const Icon(Icons.cloud_off, size: 48, color: AppColors.danger),
 const SizedBox(height: 8),
 Text('Erro ao carregar: $error', textAlign: TextAlign.center),
 TextButton(onPressed: _load, child: const Text('Tentar novamente')),
 ]));
 }

 return RefreshIndicator(
 color: AppColors.primary,
 onRefresh: _load,
 child: ListView(
 padding: const EdgeInsets.only(bottom: 24),
 children: [
 // Header
 Padding(
 padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
 child: Text('Home', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textP)),
 ),

 // Just for you — hero (álbuns recentemente adicionados)
 if (newest.isNotEmpty) ...[
 const SectionHeader(title: 'Just for you'),
 SizedBox(
 height: 210,
 child: ListView.builder(
 scrollDirection: Axis.horizontal,
 padding: const EdgeInsets.symmetric(horizontal: 16),
 itemCount: newest.length,
 itemBuilder: (_, i) {
 final album = newest[i];
 return GestureDetector(
 onTap: () => Navigator.of(context).pushNamed('/album', arguments: album),
 child: Container(
 width: 170,
 margin: const EdgeInsets.only(right: 12),
 child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 CoverArt(coverArtId: album.coverArt, size: 170),
 const SizedBox(height: 8),
 Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis,
 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textP)),
 Text(album.artist, maxLines: 1,
 style: TextStyle(fontSize: 12, color: AppColors.textSecondary(b))),
 ]),
 ),
 );
 },
 ),
 ),
 ],

 // Trending today — mais tocados
 if (frequent.isNotEmpty) ...[
 const SectionHeader(title: 'Trending today'),
 SizedBox(
 height: 180,
 child: ListView.builder(
 scrollDirection: Axis.horizontal,
 padding: const EdgeInsets.symmetric(horizontal: 16),
 itemCount: frequent.length,
 itemBuilder: (_, i) {
 final album = frequent[i];
 return GestureDetector(
 onTap: () => Navigator.of(context).pushNamed('/album', arguments: album),
 child: Container(
 width: 140,
 margin: const EdgeInsets.only(right: 12),
 child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 Stack(children: [
 CoverArt(coverArtId: album.coverArt, size: 140),
 ]),
 const SizedBox(height: 6),
 Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis,
 style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textP)),
 // linha colorida sob o nome (ref 17.50.11)
 Container(height: 3, width: 40, color: AppColors.primary),
 const SizedBox(height: 2),
 Text(album.artist, maxLines: 1,
 style: TextStyle(fontSize: 12, color: AppColors.textSecondary(b))),
 ]),
 ),
 );
 },
 ),
 ),
 ],

 // Top artists — círculos
 if (artists.isNotEmpty) ...[
 const SectionHeader(title: 'Top artists'),
 SizedBox(
 height: 130,
 child: ListView.builder(
 scrollDirection: Axis.horizontal,
 padding: const EdgeInsets.symmetric(horizontal: 16),
 itemCount: artists.length,
 itemBuilder: (_, i) {
 final artist = artists[i];
 return GestureDetector(
 onTap: () => Navigator.of(context).pushNamed('/artist', arguments: artist),
 child: Container(
 width: 90,
 margin: const EdgeInsets.only(right: 12),
 child: Column(children: [
 ClipOval(child: CoverArt(coverArtId: artist.coverArt, size: 80, radius: 40)),
 const SizedBox(height: 6),
 Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis,
 style: TextStyle(fontSize: 12, color: textP)),
 ]),
 ),
 );
 },
 ),
 ),
 ],

 // Picked for you — músicas aleatórias
 if (random.isNotEmpty) ...[
 const SectionHeader(title: 'Picked for you'),
 ...random.take(5).map((s) => SongTile(song: s, queue: random)),
 ],
 ],
 ),
 );
 }
}