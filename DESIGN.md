# Stack Music — Design System (Flutter)

App de música unificado: servidor Navidrome (Subsonic API) + busca/download/streaming via API própria (music-download-api). Design extraído das 8 referências analisadas com o modelo de visão (MusicBox, players coloridos, playlist rosa/soft-UI, Discover, My Music, Home dark, Browse).

## Identidade

Nome: **Stack Music**. Logotipo: nota musical sobre ondas empilhadas (stack).

## Princípios

- **Dark-first** (base #121212-like) com modo claro (branco) — refs Home dark + MusicBox claro
- Base neutra; **um único accent vibrante**: amarelo/dourado #FADC40 (refs 17.48.19, 17.49.34, 17.49.38, 17.49.44)
- Índigo/roxo (#6A3FFB-like → gradiente #151354→#2C1656) reservado ao Now Playing (refs 17.43.15, 17.48.51)
- Flat design com **toques soft-UI/neomórficos** sutis em botões e cards (refs 17.48.51, 17.49.44)
- Card-based UI, cantos arredondados, whitespace generoso, tipografia sans-serif bold hierárquica

## Paleta

| Token | Dark | Light | Uso |
|---|---|---|---|
| background | #0E0F13 | #FFFFFF | fundo |
| surface | #1A1B21 | #FFFFFF | cards (light: entorno cinza muito claro #F2F2F2) |
| surface2 | #24262E | #EDEDEF | listas, chips inativos |
| primary (accent) | #FADC40 | #E8B923 | play/pause, barra de progresso, like, ícone ativo da nav, botões Play all |
| secondary accent | #6A3FFB | #4B44E0 | logo, links "Show all", gradiente do player |
| danger | #DA1A1C | #C41719 | delete |
| textPrimary | #F5F6FA | #101216 | |
| textSecondary | #9AA0AE | #6F6F92 | |
| playerGradient | #151354 → #2C1656 | #C9CFFF → #FAB3D4 | fundo Now Playing |
| progressWave | #FADC40 | #E8B923 | barra de progresso estilo onda |

## Tipografia

- Fonte: Inter (fallback SF Pro / Roboto) — sans-serif geométrica
- Título de tela: 24–28sp/700, alinhado à esquerda (Discover, My music, Home, Browse)
- Título de seção: 18sp/700 ("Trending today", "Popular playlist") + link "Show all" 13sp/secondary à direita
- Faixa: título 15sp/600, artista 13sp/400 textSecondary
- Rótulos pequenos: 11sp uppercase tracking-wide ("PLAYLIST", "MONTHLY LISTENERS")

## Navegação e estrutura de telas

- **Bottom nav** (persistente, 4 itens): Home, Search, Library, Downloads — ativo preenchido na cor primary
- **Mini-player fixo** acima da nav bar quando tocando (ref 17.48.51: fundo primary, ícone pause, artista/título, chevron-up para expandir)
- **Home** (refs 17.50.11 + 17.43.15): carrosséis horizontais — "Trending today" (cards com nome sobre capa + linha colorida), "Top artists" (círculos), "Picked for you", "New releases"; hero "Just for you"
- **Discover/Search** (refs 17.49.34/38): barra de busca arredondada com lupa; banner paginado; chips de gênero (Rock, Hip-hop, K-Pop com contador em sobrescrito); segmented "Recommend"/"Focus on"; grade 2 colunas + listas verticais
- **Library/My music** (refs 17.49.44 + 17.50.11): perfil com avatar circular + stats; chips de filtro (Playlists, Álbums, Artistas, Podcasts); lista com miniatura, título, "N songs", chevron; botões Play all/Collect
- **Artist Profile** (ref 17.43.15): capa grande, stats (monthly listeners, followers, nº de álbuns/singles), tabs ALBUMS | SINGLES | POPULAR com lista "Popular"
- **Playlist** (ref 17.48.51): header "PLAYLIST" + nome + seta-baixo; lista de faixas com play/pause por item, faixa ativa com barra de progresso primary; duração à direita; like por faixa
- **Now Playing** (refs 17.48.19, 17.49.44, 17.48.51): capa grande central (opção vinil giratório com braço de toca-discos); título bold central + artista; like, repeat, shuffle, more; barra de progresso com scrubber primary e tempos; controles prev/play/next grandes circulares (play preenchido primary); "SWIPE UP FOR LYRICS" no topo; ícone de download por faixa
- **Browse** (ref 17.51.01): tabs Moods/Artists/Podcasts com indicador primary; cards horizontais com texto sobre imagem (Party Theme, Romantic)
- **Login** (Navidrome manual): URL, usuário, senha, botão Conectar; validação via ping Subsonic; construído por último

## Componentes

- Cards: raio 12px, sombra sutil (soft-UI discreto), fundo surface
- Botões circulares de controle: efeito emboss/deboss neomórfico sutil
- Chips/pills: raio 999px; ativo preenchido primary com texto escuro
- Capas: quadradas raio 16px; avatares de artista circulares; colagem 2x2 para playlists
- Ícones: Material Symbols outline 24px; ativo = preenchido
- Micro-animações: 200–250ms; hero animation capa → Now Playing; vinil com rotação contínua
- Indicadores: dots de paginação no banner; contadores em sobrescrito nos chips de gênero

## Regras UI/UX

- Contraste alto: branco sobre escuro, preto sobre primary
- Espaçamento: 16px lateral, 24px entre seções; whitespace generoso
- Imagens de capa como protagonista da interface
- Feedback visual: cor primary sempre indica estado ativo/progresso
- Mobile-first: alvos de toque ≥44px