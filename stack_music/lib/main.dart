import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/models/subsonic_models.dart';
import 'core/theme/app_theme.dart';
import 'features/album/album_screen.dart';
import 'features/artist/artist_screen.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/login/login_screen.dart';
import 'features/player/now_playing_screen.dart';
import 'features/playlist/playlist_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StackMusicApp());
}

class StackMusicApp extends StatelessWidget {
  const StackMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: Consumer<AppState>(
        builder: (context, app, _) {
          return MaterialApp(
            title: 'Stack Music',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            initialRoute: '/',
            routes: {
              '/': (_) => const RootShell(),
              '/login': (_) => const LoginScreen(),
              '/nowplaying': (_) => const NowPlayingScreen(),
              '/settings': (_) => const SettingsScreen(),
            },
            onGenerateRoute: (settings) {
              final args = settings.arguments;
              switch (settings.name) {
                case '/album':
                  return MaterialPageRoute(
                      builder: (_) => AlbumScreen(album: args as SubsonicAlbum));
                case '/artist':
                  return MaterialPageRoute(
                      builder: (_) => ArtistScreen(artist: args as SubsonicArtist));
                case '/playlist':
                  return MaterialPageRoute(
                      builder: (_) =>
                          PlaylistScreen(playlist: args as SubsonicPlaylist));
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

/// Shell com bottom nav (Home, Search, Library) + mini-player fixo.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final _screens = const [HomeScreen(), SearchScreen(), LibraryScreen()];

  @override
  Widget build(BuildContext context) {
    final configured = context.watch<AppState>().isConfigured;

    if (!configured) {
      // Primeiro uso: empurra o login por cima (app interno já construído).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      });
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const MiniPlayer(),
        NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library'),
          ],
        ),
      ]),
    );
  }
}