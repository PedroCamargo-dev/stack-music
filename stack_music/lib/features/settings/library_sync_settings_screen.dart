import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';

/// Tela de configurações da Library Sync Local-First.
/// Tudo é configurável e persistido via SharedPreferences no AppState.
class LibrarySyncSettingsScreen extends StatelessWidget {
  const LibrarySyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Library Sync')),
      body: ListView(
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 32,
        ),
        children: [
          _SectionTitle(label: 'General'),
          SwitchListTile(
            secondary: Icon(Icons.sync_outlined, color: AppColors.textSecondary(b)),
            title: const Text('Enable Library Sync'),
            subtitle: const Text('Sync library data for offline access'),
            value: app.librarySyncEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => app.setLibrarySyncEnabled(v),
          ),
          const SizedBox(height: 8),
          _SectionTitle(label: 'What to sync'),
          SwitchListTile(
          secondary: Icon(Icons.info_outline, color: AppColors.textSecondary(b)),
          title: const Text('Cache metadata'),
          subtitle: const Text('Tracks, albums, artists for offline browsing'),
          value: app.librarySyncCacheMetadata,
          activeThumbColor: AppColors.primary,
          onChanged: app.librarySyncEnabled
          ? (v) => app.setLibrarySyncCacheMetadata(v)
          : null,
          ),
          SwitchListTile(
            secondary: Icon(Icons.playlist_play_outlined, color: AppColors.textSecondary(b)),
            title: const Text('Playlists'),
            subtitle: const Text('Keep playlists available offline'),
            value: app.librarySyncPlaylists,
            activeThumbColor: AppColors.primary,
            onChanged: app.librarySyncEnabled
                ? (v) => app.setLibrarySyncPlaylists(v)
                : null,
          ),
          SwitchListTile(
            secondary: Icon(Icons.favorite_outline, color: AppColors.textSecondary(b)),
            title: const Text('Favorites'),
            subtitle: const Text('Sync starred tracks and albums'),
            value: app.librarySyncFavorites,
            activeThumbColor: AppColors.primary,
            onChanged: app.librarySyncEnabled
                ? (v) => app.setLibrarySyncFavorites(v)
                : null,
          ),
          const SizedBox(height: 8),
          _SectionTitle(label: 'Sync mode'),
          RadioGroup<String>(
            groupValue: app.librarySyncMode,
            onChanged: (String? v) {
              if (app.librarySyncEnabled && v != null) {
                app.setLibrarySyncMode(v);
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  secondary: Icon(Icons.autorenew_outlined, color: AppColors.textSecondary(b)),
                  title: const Text('Background'),
                  subtitle: const Text('Sync automatically when connected'),
                  value: 'background',
                  activeColor: AppColors.primary,
                ),
                RadioListTile<String>(
                  secondary: Icon(Icons.touch_app_outlined, color: AppColors.textSecondary(b)),
                  title: const Text('Manual only'),
                  subtitle: const Text('Sync only when you tap the button'),
                  value: 'manual',
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          if (!app.librarySyncEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                'Enable Library Sync to configure what and how data is synced for offline use.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(b),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary(b),
        ),
      ),
    );
  }
}