# FRONTEND-MAP — Stack Music (auditoria, Fase 1)

Framework: Flutter 3.47 (Material 3, dark-first), provider, dio, just_audio + audio_service, cached_network_image, shared_preferences.

## Estrutura

- `lib/main.dart` — MaterialApp, rotas nomeadas + onGenerateRoute (album/artist/playlist com argumentos), RootShell (IndexedStack + NavigationBar + MiniPlayer), gate de login com splash (`app.ready`).
- `lib/core/` — app_state (provider global), api/subsonic_client (322 linhas, auth md5+salt), api/download_api_client, models, player/player_handler, theme/app_theme (tokens).
- `lib/features/` — home, search, library, album, artist, playlist, player (now_playing), settings, login.
- `lib/shared/` — widgets.dart (CoverArt, SongTile, MiniPlayer, SectionHeader), fade_slide_in.dart.

## Tela → componentes → dados → ações → estado

| Tela | Componentes | Dados (Subsonic) | Ações | Estado | Problemas |
|---|---|---|---|---|---|
| Home | SectionHeader, carrosséis (ListView horizontal), FadeSlideIn, SongTile | getAlbumList2(newest/frequent), getArtists, getRandomSongs, getNowPlaying | tap álbum→/album, tap artista→/artist, tap música→play | local setState, loading/error | sem "See all" funcional; header sem saudação/avatar; sem Continue Listening |
| Search | TextField com debounce, chips de gênero, listas locais + externas | search3, getGenres, downloadApi.search | buscar, baixar via /download | local | resultados sem separação hierárquica clara; sem recent searches |
| Library | ChoiceChips (playlists/starred/artists/albums/radios), ListTiles | getPlaylists, getStarred2, getArtists, getAlbumList2, getInternetRadioStations | navegar, desconectar via settings | local | rádio não toca (apenas SnackBar); sem tab Favorites dedicada |
| Album | SliverAppBar imersivo, Hero, tracklist numerada | getSongsOfAlbum | Play all, Shuffle, tap faixa | local | sem favoritar álbum; sem menu de faixa |
| Artist | NestedScrollView, SliverAppBar 260, TabBar 3 tabs, grid 2 col, lista numerada | getAlbumsOfArtist, getTopSongs, getArtistInfo2 | tap álbum, play faixa | local | sem favoritar artista; sem "In playlists" |
| Playlist | SliverAppBar capa 300, botões pílula, tiles com play circular | getPlaylistSongs | Play all, Shuffle, tap faixa, like | local | sem menu/remover faixa (CRUD no client existe, UI não) |
| Now Playing | gradiente fixo, Hero capa 280, Slider, controles, letras swipe-up | stream, getLyrics, star/unstar | play/pause/next/prev, seek, shuffle, repeat, like, lyrics | global via PlayerHandler | download é SnackBar fake (viola regra "não fake"); sem Queue; sem tap artista→Artist |
| MiniPlayer | pílula primary, progresso, play/pause | player global | tap→/nowplaying | watch AppState | sem next/prev; sem swipe |
| Settings | TextFields, botões | prefs (download_api_url), disconnect | salvar URL, desconectar | local | ok |
| Login | Form, validação, ping | ping, save/clear prefs | conectar | global | funciona (fixes audio_service/cleartext) |

## Player engine (global)

PlayerHandler (BaseAudioHandler): fila ConcatenatingAudioSource, shuffle, repeat via playbackState, scrobble ao completar, savePlayQueue. Player sobrevive à navegação (global em AppState). **Fila não é exposta em UI (sem tela Queue).**

## Componentes duplicados/quebrados/incompletos

1. `_PlaylistSongTile` (playlist) duplica lógica do `SongTile` (widgets.dart) — mesmo padrão visual diferente.
2. Star/favorite usa `(context as Element).markNeedsBuild()` — hack; sem optimistic update com rollback estruturado.
3. Download no Now Playing e rádio na Library são **fake** (SnackBar) — viola "nenhuma ação fake".
4. Sem EmptyState/Skeleton/ErrorState padronizados (loading = spinner central genérico; erros = texto cru).
5. Home tem 2 estilos de card de álbum sem motivo (170 vs 140 com linha colorida).
6. MiniPlayer usa Colors.black hardcoded (ok no primary, mas sem token).

## Matriz UI → dados → endpoint (Fase 3, resumo)

CoverArt → getCoverArt · TrackRow → stream/star/scrobble · AlbumCard → getAlbumList2/getAlbum · ArtistCard → getArtists/getArtist · PlaylistCard → getPlaylists · Search → search3 + download API · Player → stream/getLyrics/savePlayQueue · Login → ping. Sem mocks no app.