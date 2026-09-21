import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stack_music/core/api/subsonic_client.dart';
import 'package:stack_music/core/app_state.dart';
import 'package:stack_music/shared/widgets.dart';

// Inspect image configuration without doing HTTP or invoking the disk cache.
Future<CachedNetworkImage> imageFor(
  WidgetTester tester, {
  required SubsonicClient client,
  double size = 44,
  double density = 3,
  String id = 'cover-a',
}) async {
  final app = AppState()..subsonic = client;
  late CachedNetworkImage image;
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: app,
      child: MediaQuery(
        data: MediaQueryData(devicePixelRatio: density),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (context) {
            final cover = CoverArt(coverArtId: id, size: size).build(context);
            image = (cover as ClipRRect).child! as CachedNetworkImage;
            return const SizedBox.shrink();
          }),
        ),
      ),
    ),
  );
  await tester.pumpWidget(const SizedBox.shrink());
  app.dispose();
  return image;
}

SubsonicClient client({
  String url = 'https://music.example.test',
  String username = 'test-user',
}) => SubsonicClient(baseUrl: url, username: username, password: 'test-only');

void main() {
  for (final density in [1.0, 2.625, 3.0]) {
    testWidgets('cover decode follows device density $density', (tester) async {
      final image = await imageFor(tester, client: client(), density: density);
      expect(image.memCacheWidth, (44 * density).ceil());
      expect(image.memCacheHeight, (44 * density).ceil());
      expect(image.width, 44);
      expect(image.height, 44);
      expect(image.fit, BoxFit.cover);
    });
  }

  testWidgets('large covers do not decode above the server source size', (tester) async {
    final image = await imageFor(tester, client: client(), size: 400);
    expect(image.memCacheWidth, 600);
    expect(image.memCacheHeight, 600);
    expect(image.width, 400);
  });

  testWidgets('cover cache survives auth URL changes but isolates accounts', (tester) async {
    final first = await imageFor(tester, client: client());
    final rebuilt = await imageFor(tester, client: client(url: 'https://music.example.test/'));
    final otherUser = await imageFor(tester, client: client(username: 'another-user'));
    final otherServer = await imageFor(tester, client: client(url: 'https://other.example.test'));
    final otherCover = await imageFor(tester, client: client(), id: 'cover-b');
    expect(first.cacheKey, isNotNull);
    expect(rebuilt.cacheKey, first.cacheKey);
    expect(otherUser.cacheKey, isNot(first.cacheKey));
    expect(otherServer.cacheKey, isNot(first.cacheKey));
    expect(otherCover.cacheKey, isNot(first.cacheKey));
    expect(first.cacheKey, isNot(contains('test-only')));
    expect(first.cacheKey, isNot(contains('test-user')));
    final freshAuthUrl = Uri.parse(first.imageUrl).replace(queryParameters: {
      ...Uri.parse(first.imageUrl).queryParameters,
      's': 'fresh-salt',
      't': 'fresh-token',
    }).toString();
    expect(
      CachedNetworkImageProvider(first.imageUrl, cacheKey: first.cacheKey),
      CachedNetworkImageProvider(freshAuthUrl, cacheKey: rebuilt.cacheKey),
    );
  });
}
