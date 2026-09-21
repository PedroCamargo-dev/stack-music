import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stack_music/core/app_state.dart';
import 'package:stack_music/core/models/subsonic_models.dart';
import 'package:stack_music/core/theme/app_theme.dart';
import 'package:stack_music/shared/widgets.dart';

void main() {
  for (final dark in [true, false]) {
    testWidgets('shared styles stay pixel-identical (${dark ? 'dark' : 'light'})', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = AppState();
      addTearDown(app.dispose);
      final song = SubsonicSong(id: 'song', title: 'Song title', artist: 'Artist name', album: 'Album', duration: 183);
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: RepaintBoundary(
            key: const ValueKey('styles'),
            child: Scaffold(
              body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Popular Artists'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ArtistCard(artist: SubsonicArtist(id: 'artist', name: 'Artist name'), size: 86),
                ),
                const SectionHeader(title: 'Recently Played'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AlbumCard(album: SubsonicAlbum(id: 'album', name: 'Album name', artist: 'Artist name', year: 2026), width: 150, onPlay: () {}),
                    const SizedBox(width: 12),
                    PlaylistCard(playlist: SubsonicPlaylist(id: 'playlist', name: 'Playlist name', songCount: 12), width: 150),
                  ]),
                ),
                const SectionHeader(title: 'Top Songs'),
                TrackRow(song: song, queue: [song], index: 0, showIndex: true),
                const Expanded(child: EmptyState(message: 'Nada encontrado')),
              ]),
              bottomNavigationBar: BottomNavigation(selectedIndex: 0, onDestinationSelected: (_) {}),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await expectLater(find.byKey(const ValueKey('styles')), matchesGoldenFile('goldens/shared_${dark ? 'dark' : 'light'}.png'));
      expect(tester.takeException(), isNull);
    });
  }
}
