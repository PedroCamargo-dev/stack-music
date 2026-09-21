import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stack_music/core/app_state.dart';
import 'package:stack_music/core/api/subsonic_client.dart';
import 'support/performance_fixtures.dart';
import 'package:stack_music/features/home/home_screen.dart';
import 'package:stack_music/features/search/search_screen.dart';
import 'package:stack_music/features/library/library_screen.dart';
import 'package:stack_music/features/favorites/favorites_screen.dart';
import 'package:stack_music/features/profile/profile_screen.dart';
import 'package:stack_music/features/settings/settings_screen.dart';

void main() {
  final fixture = FixtureClient();
  final testAppState = TestAppState(fixture);

  testWidgets('Navigate through all main screens without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: testAppState,
        child: MaterialApp(
          home: Scaffold(
            body: const HomeScreen(),
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
                BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Fav'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ],
              onTap: (index) {
                switch (index) {
                  case 0: break;
                  case 1: Navigator.of(tester.element(find.byType(HomeScreen))).push(MaterialPageRoute(builder: (_) => const SearchScreen())); break;
                  case 2: Navigator.of(tester.element(find.byType(HomeScreen))).push(MaterialPageRoute(builder: (_) => const LibraryScreen())); break;
                  case 3: Navigator.of(tester.element(find.byType(HomeScreen))).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())); break;
                  case 4: Navigator.of(tester.element(find.byType(HomeScreen))).push(MaterialPageRoute(builder: (_) => const ProfileScreen())); break;
                  case 5: Navigator.of(tester.element(find.byType(HomeScreen))).push(MaterialPageRoute(builder: (_) => const SettingsScreen())); break;
                }
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.library_music).first);
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite).first);
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person).first);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings).first);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
