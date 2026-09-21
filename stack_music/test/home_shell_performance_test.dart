import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stack_music/core/app_state.dart';
import 'package:stack_music/core/theme/app_theme.dart';
import 'package:stack_music/features/favorites/favorites_screen.dart';
import 'package:stack_music/features/home/home_screen.dart';
import 'package:stack_music/features/library/library_screen.dart';
import 'package:stack_music/features/search/search_screen.dart';
import 'package:stack_music/main.dart';
import 'package:stack_music/shared/widgets.dart';

import 'support/performance_fixtures.dart';

Future<void> mount(WidgetTester tester, TestAppState app, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(412, 915));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
    value: app,
    child: MaterialApp(theme: AppTheme.dark(), home: child),
  ));
  await tester.pumpAndSettle();
  addTearDown(app.dispose);
}

void main() {
  testWidgets('Home ignores unrelated state changes and scopes username rebuilds', (tester) async {
    final client = FixtureClient();
    final app = TestAppState(client);
    await mount(tester, app, const HomeScreen());
    var homeRebuilds = 0;
    var cardRebuilds = 0;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (element.widget is HomeScreen) homeRebuilds++;
      if (element.widget is ArtistCard) cardRebuilds++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    app.unrelatedChange();
    await tester.pump();
    app.rename('Bob');
    await tester.pump();
    debugPrint('PERF Home: home=$homeRebuilds cards=$cardRebuilds requests=${client.requests.length}');
    expect(homeRebuilds, 0);
    expect(cardRebuilds, 0);
    expect(find.text('B'), findsOneWidget);
    expect(client.requests.length, 5);
  });

  testWidgets('shell defers unused tabs and retains loaded tabs and scroll state', (tester) async {
    final client = FixtureClient();
    await mount(tester, TestAppState(client), const RootShell());
    debugPrint('PERF startup requests: ${client.requests.length} ${client.requests}');
    expect(client.requests.length, 5);
    expect(find.byType(SearchScreen, skipOffstage: false), findsNothing);
    expect(find.byType(LibraryScreen, skipOffstage: false), findsNothing);
    expect(find.byType(FavoritesScreen, skipOffstage: false), findsNothing);

    final homeState = tester.state(find.byType(HomeScreen));
    final homeList = find.descendant(of: find.byType(HomeScreen), matching: find.byType(ListView)).first;
    await tester.drag(homeList, const Offset(0, -400));
    await tester.pumpAndSettle();
    final homeScrollable = find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first;
    final offset = tester.state<ScrollableState>(homeScrollable).position.pixels;
    expect(offset, greaterThan(0));

    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    final libraryState = tester.state(find.byType(LibraryScreen));
    final requestCount = client.requests.length;
    final hiddenHome = tester.element(find.byType(HomeScreen, skipOffstage: false));
    expect(TickerMode.of(hiddenHome), isFalse);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(HomeScreen)), same(homeState));
    expect(tester.state<ScrollableState>(homeScrollable).position.pixels, offset);
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(LibraryScreen)), same(libraryState));
    expect(client.requests.length, requestCount);
    expect(tester.takeException(), isNull);
  });
}
