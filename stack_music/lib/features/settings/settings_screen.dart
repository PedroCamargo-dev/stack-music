import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';

/// Settings: URL da download API, modo claro/escuro, desconectar do Navidrome.
class SettingsScreen extends StatefulWidget {
 const SettingsScreen({super.key});

 @override
 State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
 late final TextEditingController _apiUrlController;

 @override
 void initState() {
 super.initState();
 _apiUrlController = TextEditingController(text: context.read<AppState>().downloadApiUrl);
 }

 @override
 void dispose() {
 _apiUrlController.dispose();
 super.dispose();
 }

 @override
 Widget build(BuildContext context) {
 final b = Theme.of(context).brightness;
 final textP = AppColors.textPrimary(b);
 final textS = AppColors.textSecondary(b);
 final app = context.watch<AppState>();

 return Scaffold(
 appBar: AppBar(title: const Text('Settings')),
 body: ListView(
 padding: const EdgeInsets.all(16),
 children: [
 Text('Download API', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textP)),
 const SizedBox(height: 4),
 Text('Servidor de busca/download (YouTube + Spotify)',
 style: TextStyle(fontSize: 13, color: textS)),
 const SizedBox(height: 12),
 TextField(
 controller: _apiUrlController,
 decoration: InputDecoration(
 hintText: 'http://192.168.0.10:3333',
 filled: true,
 fillColor: AppColors.surface2(b),
 border: OutlineInputBorder(
 borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
 ),
 ),
 const SizedBox(height: 8),
 FilledButton.icon(
 style: FilledButton.styleFrom(
 backgroundColor: AppColors.primary, foregroundColor: Colors.black),
 onPressed: () => app.setDownloadApiUrl(_apiUrlController.text.trim()),
 icon: const Icon(Icons.save),
 label: const Text('Salvar')),
 const SizedBox(height: 32),
 Text('Servidor Navidrome', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textP)),
 const SizedBox(height: 4),
 Text(app.subsonic?.baseUrl ?? 'não conectado',
 style: TextStyle(fontSize: 13, color: textS)),
 const SizedBox(height: 12),
 OutlinedButton.icon(
 style: OutlinedButton.styleFrom(
 foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
 onPressed: () async {
 await app.disconnect();
 if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
 },
 icon: const Icon(Icons.logout),
 label: const Text('Desconectar')),
 ],
 ),
 );
 }
}