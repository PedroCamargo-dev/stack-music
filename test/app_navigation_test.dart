import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stack_music/main.dart';
import 'package:stack_music/core/app_state.dart';
import 'package:stack_music/core/api/subsonic_client.dart';
import 'support/performance_fixtures.dart';

void main() {
  final fixture = FixtureClient();
  final testAppState = TestAppState(fixture);

  testWidgets('Navigate through all main screens without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: testAppState,
        child: const StackMusicApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.library_music));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
