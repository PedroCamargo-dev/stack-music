# Stack Music — Design System (Flutter)

App de música unificado: servidor Navidrome (Subsonic API) + busca/download/streaming via API própria (music-download-api). Mescla das 13 referências enviadas (MusicBox, Discover, My Music, Browse, players escuros e claros).

## Identidade

Nome: **Stack Music**. Logotipo: nota musical sobre ondas empilhadas (stack).

## Paleta (dark-first, com modo claro)

| Token | Dark | Light | Uso |
|---|---|---|---|
| background | #0E0F13 | #F6F6F7 | fundo |
| surface | #1A1B21 | #FFFFFF | cards |
| surface2 | #24262E | #EDEDEF | listas, chips |
| primary | #5B6CFF | #3A47E8 | ações, links (índigo das refs 17.41/17.43) |
| accent | #FADC40 | #E8B923 | destaque "Trending"/badges (ref 17.48.19) |
| danger | #DA1A1C | #C41719 | delete |
| textPrimary | #F5F6FA | #101216 |
| textSecondary | #9AA0AE | #6F6F92 |
| playerGradient | #151354 → #2C1656 | #C9CFFF → #FAB3D4 | fundo do player (Now Playing) |

## Tipografia

- Display/ títulos: 22–28sp, peso 700
- Título de faixa: 15sp/600; artista: 13sp/400 textSecondary
- Seções (Home): 18sp/700 + "Show all" 13sp primary à direita
- Fonte: Inter (fallback: SF/Roboto)

## Componentes mesclados das referências

- **Home** (refs 17.50.11, 17.41): seções horizontais — "Just for you" (destaques grandes), "New releases", "Trending today" com badge amarela, "Top artists", "Picked for you". Tabs inferiores: Home, Search, Library, Downloads.
- **Discover/Search** (refs 17.49.34/38): barra de busca arredondada, chips de gênero (Rock, Hip-hop, K-Pop...), "Daily music", "Popular playlists", recomendações verticais.
- **Library / My music** (ref 17.49.44): avatares de playlists (colagem 2x2), contagem de músicas, seções Recentes/Playlists/Artistas.
- **Artist Profile** (ref 17.41): capa grande, listeners/followers, tabs ALBUMS | SINGLES | POPULAR.
- **Now Playing** (refs 17.42, 17.48.19): capa grande central, progresso, controles, "SWIPE UP FOR LYRICS", fundo em gradiente índigo.
- **Playlist** (ref 17.48.51): header com capa + lista de faixas (artista, duração).
- **Login** (conexão manual Navidrome): URL, usuário, senha, botão Conectar; validação com ping Subsonic.

## Regras UI/UX

- Cantos: 12px cards, 16px capas, 999px chips/botões pill
- Capas 1:1 com hero noise; imagem via `getCoverArt`
- Espaçamento 16px lateral; 24px entre seções
- Ícones outline 24px (Material Symbols)
- Micro-animações: 200–250ms, hero animation capa → player
- Player persistente (mini-player) acima da tab bar