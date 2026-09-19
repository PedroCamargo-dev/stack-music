import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/api/download_api_client.dart';
import '../../core/models/subsonic_models.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets.dart';

/// Discover/Search (refs 17.49.34/38): busca local (search3) e busca externa
/// via music-download-api, com botão de download por resultado.
class SearchScreen extends StatefulWidget {
 const SearchScreen({super.key});

 @override
 State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
 final _controller = TextEditingController();
 Timer? _debounce;

 SearchResult? local;
 List<SearchItem> externalResults = [];
 List<SubsonicGenre> genres = [];
 bool searching = false;
 bool downloading = false;
 String downloadLog = '';

 @override
 void initState() {
 super.initState();
 _loadGenres();
 }

 Future<void> _loadGenres() async {
 try {
 genres = await context.read<AppState>().subsonic!.getGenres();
 if (mounted) setState(() {});
 } catch (_) {}
 }

 void _onChanged(String q) {
 _debounce?.cancel();
 if (q.trim().length < 2) {
 setState(() { local = null; externalResults = []; });
 return;
 }
 _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
 }

 Future<void> _search(String q) async {
 setState(() => searching = true);
 final app = context.read<AppState>();
 try {
 final results = await Future.wait([
 app.subsonic!.search3(q),
 app.downloadApi?.search(q) ?? Future.value(null),
 ]);
 if (!mounted) return;
 setState(() {
 local = results[0] as SearchResult;
 externalResults = (results[1] as DownloadSearchResponse?)?.items ?? [];
 searching = false;
 });
 } catch (e) {
 if (mounted) setState(() { searching = false; });
 }
 }

 Future<void> _download(SearchItem item) async {
 final app = context.read<AppState>();
 setState(() { downloading = true; downloadLog = ''; });
 try {
 await for (final line in app.downloadApi!.download([item.url])) {
 if (!mounted) return;
 setState(() => downloadLog = line);
 }
 if (mounted) {
 setState(() => downloadLog = 'Download concluído: ${item.title}');
 }
 } catch (e) {
 if (mounted) setState(() => downloadLog = 'Erro: $e');
 } finally {
 if (mounted) setState(() => downloading = false);
 }
 }

 @override
 void dispose() {
 _debounce?.cancel();
 _controller.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 final textP = AppColors.textPrimary(b);
 final textS = AppColors.textSecondary(b);

 return Scaffold(
 body: SafeArea(
 child: ListView(
 padding: const EdgeInsets.only(bottom: 24),
 children: [
 Padding(
 padding: const EdgeInsets.all(16),
 child: Text('Discover', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textP)),
 ),
 // Barra de busca arredondada (refs 17.49.34/38)
 Padding(
 padding: const EdgeInsets.symmetric(horizontal: 16),
 child: TextField(
 controller: _controller,
 onChanged: _onChanged,
 decoration: InputDecoration(
 hintText: 'Search musics...',
 prefixIcon: const Icon(Icons.search),
 filled: true,
 fillColor: AppColors.surface2(b),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(999),
 borderSide: BorderSide.none),
 ),
 ),
 ),
 // Chips de gênero com contador (ref 17.48.19)
 if (genres.isNotEmpty && local == null)
 SizedBox(
 height: 48,
 child: ListView.builder(
 scrollDirection: Axis.horizontal,
 padding: const EdgeInsets.all(8),
 itemCount: genres.length,
 itemBuilder: (_, i) {
 final g = genres[i];
 return Padding(
 padding: const EdgeInsets.only(right: 8),
 child: Chip(
 label: Text('${g.name}  ${g.songCount}'),
 ),
 );
 },
 ),
 ),
 if (searching) const Padding(
 padding: EdgeInsets.all(24),
 child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
 ),

 // Resultados locais (Navidrome)
 if (local != null) ...[
 if (local!.artists.isNotEmpty) ...[
 const SectionHeader(title: 'Artists'),
 ...local!.artists.map((a) => ListTile(
 leading: ClipOval(child: CoverArt(coverArtId: a.coverArt, size: 48, radius: 24)),
 title: Text(a.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textP)),
 subtitle: Text('${a.albumCount ?? 0} albums', style: TextStyle(fontSize: 13, color: textS)),
 onTap: () => Navigator.of(context).pushNamed('/artist', arguments: a),
 )),
 ],
 if (local!.albums.isNotEmpty) ...[
 const SectionHeader(title: 'Albums'),
 ...local!.albums.map((a) => ListTile(
 leading: CoverArt(coverArtId: a.coverArt, size: 48, radius: 8),
 title: Text(a.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textP)),
 subtitle: Text(a.artist, style: TextStyle(fontSize: 13, color: textS)),
 onTap: () => Navigator.of(context).pushNamed('/album', arguments: a),
 )),
 ],
 if (local!.songs.isNotEmpty) ...[
 const SectionHeader(title: 'Songs'),
 ...local!.songs.map((s) => SongTile(song: s, queue: local!.songs)),
 ],
 ],

 // Resultados externos (download API)
 if (externalResults.isNotEmpty) ...[
 const SectionHeader(title: 'Find & download'),
 ...externalResults.map((item) => ListTile(
 leading: ClipRRect(
 borderRadius: BorderRadius.circular(8),
 child: item.thumbnail.isEmpty
 ? Container(width: 48, height: 48, color: AppColors.surface2(b),
 child: Icon(Icons.music_note, color: textS))
 : Image.network(item.thumbnail, width: 48, height: 48, fit: BoxFit.cover),
 ),
 title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
 style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textP)),
 subtitle: Text('${item.platform} · ${item.artist}${item.duration != null ? ' · ${item.duration}' : ''}',
 style: TextStyle(fontSize: 13, color: textS)),
 trailing: downloading
 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
 : IconButton(
 icon: const Icon(Icons.download, color: AppColors.primary),
 onPressed: () => _download(item),
 ),
 )),
 ],
 if (downloadLog.isNotEmpty)
 Padding(
 padding: const EdgeInsets.all(16),
 child: Text(downloadLog, style: TextStyle(fontSize: 12, color: textS)),
 ),
 ],
 ),
 ),
 );
 }
}