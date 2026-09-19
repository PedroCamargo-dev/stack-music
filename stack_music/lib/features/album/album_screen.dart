import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Tela de álbum: capa grande, metadados, Play all e lista de faixas.
class AlbumScreen extends StatefulWidget {
 final SubsonicAlbum album;
 const AlbumScreen({super.key, required this.album});

 @override
 State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
 List<SubsonicSong> songs = [];
 bool loading = true;
 String? error;

 @override
 void initState() {
 super.initState();
 _load();
 }

 Future<void> _load() async {
 setState(() { loading = true; error = null; });
 try {
 final s = await context.read<AppState>().subsonic!.getSongsOfAlbum(widget.album.id);
 setState(() { songs = s; loading = false; });
 } catch (e) {
 setState(() { loading = false; error = e.toString(); });
 }
 }

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 final textP = AppColors.textPrimary(b);
 final textS = AppColors.textSecondary(b);
 final album = widget.album;

 return Scaffold(
 body: SafeArea(
 child: loading
 ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
 : error != null
 ? Center(child: Text('Erro: $error'))
 : RefreshIndicator(
 color: AppColors.primary,
 onRefresh: _load,
 child: ListView(
 padding: const EdgeInsets.only(bottom: 24),
 children: [
 Row(children: [
 IconButton(
 icon: Icon(Icons.arrow_back, color: textP),
 onPressed: () => Navigator.of(context).pop(),
 ),
 ]),
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 16),
 child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
 Hero(
 tag: 'album-${album.id}',
 child: CoverArt(coverArtId: album.coverArt, size: 160)),
 const SizedBox(width: 16),
 Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 Text(album.name,
 style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textP)),
 const SizedBox(height: 4),
 Text(album.artist, style: TextStyle(fontSize: 14, color: textS)),
 const SizedBox(height: 4),
 Text(
 '${album.songCount} songs · ${album.year ?? ''}${album.genre != null ? ' · ${album.genre}' : ''}',
 style: const TextStyle(fontSize: 12, letterSpacing: 1.2, color: textS)),
 ])),
 ]),
 ),
 const SizedBox(height: 16),
 // Play all (ref 17.49.34)
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 16),
 child: FilledButton.icon(
 style: FilledButton.styleFrom(
 backgroundColor: AppColors.primary,
 foregroundColor: Colors.black),
 onPressed: () => context.read<AppState>().player?.playQueue(songs),
 icon: const Icon(Icons.play_arrow),
 label: const Text('Play all'),
 ),
 ),
 const SizedBox(height: 8),
 for (final s in songs)
 SongTile(song: s, queue: songs),
 ],
 ),
 ),
 ),
 );
 }
}