import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_music/core/app_state.dart';
import 'package:stack_music/core/offline/download_quality.dart';
import 'package:stack_music/features/downloads/downloads_screen.dart';
import 'package:stack_music/features/settings/settings_screen.dart';

import '../support/performance_fixtures.dart';

void main() {
  testWidgets('Settings abre o gerenciador de downloads', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final app = TestAppState(FixtureClient());

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: MaterialApp(
          home: const SettingsScreen(),
          routes: {
            '/downloads': (_) => const DownloadsScreen(),
          },
        ),
      ),
    );

    expect(find.text('Downloads'), findsOneWidget);
    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();

    expect(find.byType(DownloadsScreen), findsOneWidget);
  });

  testWidgets('Settings persiste a qualidade de download escolhida',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = TestAppState(FixtureClient());

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: app,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('Download quality'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Média (192 kbps)'));
    await tester.pumpAndSettle();

    expect((app as dynamic).downloadQuality, DownloadQuality.medium);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('download_quality'), 'medium');
  });
}
