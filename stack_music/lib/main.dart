import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/album/album_screen.dart';
import 'features/artist/artist_screen.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
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
              '/nowplaying': (_) => const NowPlayingScreen(),
              '/settings': (_) => const SettingsScreen(),
              '/album': (ctx) =>
                  AlbumScreen(album: ctx.settings.arguments as dynamic),
              '/artist': (ctx) =>
                  ArtistScreen(artist: ctx.settings.arguments as dynamic),
              '/playlist': (ctx) =>
                  PlaylistScreen(playlist: ctx.settings.arguments as dynamic),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/login') {
                return MaterialPageRoute(
                    builder: (_) => const LoginGate());
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

/// Gate de login: enquanto não houver conexão salva, mostra a LoginScreen.
class LoginGate extends StatelessWidget {
  const LoginGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        return app.isConfigured ? const RootShell() : const _LoginProxy();
      },
    );
  }
}

class _LoginProxy extends StatelessWidget {
  const _LoginProxy();

  @override
  Widget build(BuildContext context) {
    // Import tardio evita ciclo; tela real em features/login/login_screen.dart
    return const LoginScreenHost();
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