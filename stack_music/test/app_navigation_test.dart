import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stack_music/core/app_state.dart';
import 'package:stack_music/main.dart';
import 'package:stack_music/features/home/home_screen.dart';
import 'package:stack_music/features/search/search_screen.dart';
import 'package:stack_music/features/library/library_screen.dart';
import 'package:stack_music/features/favorites/favorites_screen.dart';
import 'package:stack_music/features/settings/settings_screen.dart';

import 'support/performance_fixtures.dart';

void main() {
  testWidgets('Navigate through all main tabs without crash', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fixture = FixtureClient();
    final app = TestAppState(fixture);

    await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
    value: app,
    child: MaterialApp(home: const RootShell()),
    ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);

    // Tap Search tab
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);

    // Tap Library tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);

    // Tap Favorites tab
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    // Return to Home
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}