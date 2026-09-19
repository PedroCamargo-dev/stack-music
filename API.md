# Stack Music — Mapeamento de APIs

## 1. Navidrome / Subsonic API (v1.16.1, compatível)

Base: `{serverUrl}/rest/{endpoint}?u={user}&t={token}&s={salt}&v=1.16.1&c=stackmusic&f=json`

**Autenticação**: token = md5(password + salt) (salt aleatório ≥6 chars, hex lowercase). Nunca enviar senha em claro.

### Endpoints utilizados no app

| Endpoint | Uso no app |
|---|---|
| `ping` | Validação do login (tela de configuração) |
| `getArtists` / `getArtist` | Library: lista/tela de artista |
| `getAlbumList2` (type=newest, frequent, random) | Home: New releases, Picked for you |
| `getAlbum` | Tela de álbum + faixas |
| `getStarred2` | Favoritos |
| `search3` | Busca local (artistCount, albumCount, songCount) |
| `getPlaylists` / `getPlaylist` | Playlists |
| `createPlaylist` / `updatePlaylist` / `deletePlaylist` | CRUD playlists |
| `getRandomSongs`, `getSongsByGenre`, `getGenres` | Discover: Daily music, chips de gênero |
| `getNowPlaying` | (opcional) |
| `stream` | Streaming de áudio (id, format, maxBitRate) |
| `download` | Download direto (server-side) |
| `getCoverArt` | Capas (id, size) |
| `getLyrics` | Letras no player |
| `star` / `unstar` | Like por faixa/álbum/artista |
| `scrobble` (submission=true) | Marcar como tocada |
| `getPlayQueue` / `savePlayQueue` | Fila persistente entre sessões |
| `getUser` | Permissões (downloadRole etc.) |
| `startScan` / `getScanStatus` | (admin) scan da biblioteca |

Notas Navidrome: IDs sempre string; sem suporte a browse-by-folder; `stream` não scrobleia (usar `scrobble`).

## 2. music-download-api (API própria, Go/Gin, porta 3333)

| Endpoint | Método | Descrição |
|---|---|---|
| `/search?query=&type=track,artist,playlist,album&limit=&offset=&youtube_type=video,playlist&maxResults=` | GET | Busca unificada YouTube + Spotify. Resposta: `{youtube: {videos, playlists}, spotify: {tracks, artists, playlists, albums, pagination}}` |
| `/process-urls` | POST | Body `{"urls": [...]}` → metadados por tipo `{tracks, playlists, albums, artists}` (title, thumbnail, duration, track_count) |
| `/download` | POST | Body `{"urls": [...]}` → streaming de texto com progresso (chunked). Spotify via spotdl, YouTube via ytmdl/yt-dlp. Arquivos caem em `/downloads` do servidor |

No app: tela Discover/Search usa `/search`; ação "Baixar" chama `/download` (stream de progresso) — músicas baixadas caem na pasta monitorada pelo Navidrome e aparecem na biblioteca após scan.