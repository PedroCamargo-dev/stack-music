# REFERENCE-ANALYSIS — Engenharia reversa das 8 referências (Fase 2)

Regra: referências = estrutura/UX/composição apenas. Paleta, tokens e identidade vêm do projeto (dark #0E0F13, primary #FADC40, índigo no player).

## Matriz REFERÊNCIA → ELEMENTO → FUNÇÃO → USAR? → ONDE

| Ref | Elemento | Função | Usar? | Onde/Como adaptar |
|---|---|---|---|---|
| 17.50.11 (Home dark/Lib) | Header logo + ícones search/profile | âncora persistente | Sim | Home: título + ícone busca + avatar |
| | "Show all" por seção | ver tudo | Sim | SectionHeader.onShowAll → tela lista (implementar rotas) |
| | Trending cards com nome sobre capa + accent line | destaque | Sim | Home "Mais tocados" |
| | Top artists círculos | scannear artistas | Sim | Home (já existe, padronizar 80px) |
| | Library: chips filtro + Recents lista + toggle grid/list | filtrar | Sim | Library (chips existem; adicionar toggle) |
| 17.43.15 (MusicBox) | "Just for you" carrossel quadrado | recomendação | Sim | Home hero (já existe) |
| | Top songs lista numerada + menu ... | ranking | Sim | Home/Artista POPULAR (artista já tem) |
| | Now Playing compacto + "SWIPE UP FOR LYRICS" | player | Parcial | Full player (já tem hint; consolidar) |
| | Artist Profile: stats em colunas (ÁLBUNS/SINGLES/FOLLOWERS) | hierarquia de dados | Parcial | Só dados reais do Navidrome (álbuns, faixas); sem followers/ouvintes inventados |
| 17.48.19 (vinil/colorido) | Player vinil + braço de toca-discos | personalidade | Sim (opcional) | Full player modo vinil girando quando playing |
| | Tabs grandes ativas vs inativas (Artists/Playlists) | navegação por aba | Sim | Library/Artist tabs |
| | Chips de gênero com contador sobrescrito | filtro por gênero | Sim | Search chips (getGenres com songCount) |
| | Pilha de cards rotacionados (New songs) | descoberta | Não (prioridade baixa) | — |
| 17.48.51 (playlist soft-UI) | Lista com play/pause circular por item | estado por faixa | Sim | Playlist (já implementado) |
| | Faixa ativa com barra de progresso embutida | feedback | Sim | Playlist/Home (já existe) |
| | Mini-player pílula persistente com chevron-up | controle global | Sim | MiniPlayer (adicionar chevron e next) |
| | Botões de transporte em pílula flutuante | controles | Parcial | Full player: manter layout clássico; pílula no mini |
| 17.49.34 (Discover) | Search bar arredondada + banner paginado + Daily music | descoberta | Parcial | Search já tem barra; banner = dispensável (sem conteúdo promocional real) |
| | "Popular playlist" + "All" | lista horizontal | Sim | Search/Library |
| 17.49.38 (Discover/Dynamic) | Segmented Recommend/Focus | filtro | Não | sem dados distintos no Navidrome |
| | Masonry grid | feed visual | Não | listas precisam escaneabilidade |
| | Bottom nav flutuante 3 itens | navegação | Parcial | manter NavigationBar padrão M3 (identidade) |
| 17.49.44 (My music/vinil) | Card de perfil com stats + ações rápidas 4 colunas | profile | Sim | Profile/My music (adaptar: playlists, favoritos, histórico, downloads se reais) |
| | Player com waveform + vinil | progresso | Parcial | full player: slider padrão (waveform sem dados reais) |
| 17.51.01 (Browse) | Tabs Moods/Artists + cards com texto sobre imagem | categorias | Parcial | Browse por gêneros (getGenres) se agregado na Library; não inventar moods |

## Decisões de design (Fase 4 — IA unificada)

- Nav inferior: Home, Search, Library, Favorites (4ª tab); Profile fica no header da Library (avatar) — evita 5ª tab.
- Home modular com "See all" funcional; seções ocultas quando vazias.
- Full player: artwork dominante, hero, like/repeat/shuffle, swipe-down fecha, tap artista→Artist, fila (Queue) como bottom sheet.
- Mini player global persistente (não reinicia): pílula com cover, título, play/pause, next, chevron-up.
- Estados padronizados: Skeleton (loading), EmptyState (por seção), ErrorState com retry.
- Componentes: TrackRow (unifica SongTile/_PlaylistSongTile), AlbumCard, ArtistCard, PlaylistCard, SectionHeader (See all), QueueSheet, OverflowMenu (ações reais apenas).
- Sem ações fake: download só quando funcional (download API); rádio toca streamUrl com just_audio.

## Pendências mapeadas (para fases 6–16)
1. Remover SnackBar fake de download e rádio → implementar real ou esconder.
2. Queue screen (fila global do PlayerHandler) — não existe.
3. See all sem destino (SectionHeader.onShowAll null em vários lugares).
4. Unificar duplicações de tile de música; substituir hack markNeedsBuild por setState/provider.
5. Empty/Skeleton states padronizados.
6. Favorites como tab completa (songs/albums/artists starred).