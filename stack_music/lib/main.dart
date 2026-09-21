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
import 'features/favorites/favorites_screen.dart';
import 'features/profile/profile_screen.dart';
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
              '/favorites': (_) => const FavoritesScreen(),
              '/profile': (_) => const ProfileScreen(),
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

/// App Shell: Conteúdo → Mini Player → Bottom Navigation.
/// Respeita safe-area superior/inferior. Navegação não interrompe reprodução.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    // 1. Splash apenas enquanto carrega credenciais salvas
    if (!app.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // 2. Se não configurado, mostra APENAS o login (sem shell/tabs por baixo)
    if (!app.isConfigured) {
      return const LoginScreen();
    }

    // 3. Shell principal apenas quando logado
    return const _MainShell();
  }
}

/// Shell interno (tabs + mini player) — só renderizado após login.
class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _index = 0;
  late final ValueNotifier<int> _tabIndex;
  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabIndex = ValueNotifier<int>(0);
    _tabIndex.addListener(() {
      if (_tabIndex.value != _index) setState(() => _index = _tabIndex.value);
    });
  }

  @override
  void dispose() {
    _tabIndex.dispose();
    super.dispose();
  }

  void _switchTab(int i) => _tabIndex.value = i;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: [
          HomeScreen(tabIndex: _tabIndex),
          ..._screens.skip(1),
        ]),
      ),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const MiniPlayer(),
        BottomNavigation(
          selectedIndex: _index,
          onDestinationSelected: _switchTab,
        ),
      ]),
    );
  }
}