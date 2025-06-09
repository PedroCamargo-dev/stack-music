// src/types/shared.ts

/**
 * === Search / Busca (app/api/search/route.ts e front-end) ===
 */

/**
 * Representa um artista unificado (Spotify & YouTube).
 */
export interface Artist {
  id: string;
  name: string;
  genres: string[];
  popularity: number;
  followers: {
    total: number;
  };
  images: {
    url: string;
  }[];
  external_urls: {
    spotify: string;
  };
  platform: "spotify" | "youtube";
}

/**
 * Representa um álbum unificado (Spotify & YouTube).
 */
export interface Album {
  id: string;
  name: string;
  album_type: string;
  artists: {
    name: string;
    external_urls: { spotify: string };
  }[];
  release_date: string;
  total_tracks: number;
  images: {
    url: string;
  }[];
  external_urls: {
    spotify: string;
  };
  platform: "spotify" | "youtube";
}

/**
 * Versão “Spotify” de Track (campo album, duração, popularidade, preview etc).
 */
export interface SpotifyTrack {
  id: string;
  name: string;
  album: {
    name: string;
    images: {
      url: string;
    }[];
  };
  artists: {
    name: string;
  }[];
  duration_ms: number;
  external_urls: {
    spotify: string;
  };
  popularity: number;
  explicit: boolean;
  preview_url: string | null;
  platform: "spotify";
}

/**
 * Versão “YouTube” de Track (campo thumbnail, canal, data de publicação).
 */
export interface YouTubeTrack {
  id: string;
  name: string;
  artists: {
    name: string;
  }[];
  external_urls: {
    youtube: string;
  };
  platform: "youtube";
  thumbnail: string;
  channelTitle: string;
  publishedAt: string;
}

/**
 * Tipo unificado de Track, que pode ser SpotifyTrack ou YouTubeTrack.
 */
export type Track = SpotifyTrack | YouTubeTrack;

/**
 * Versão “Spotify” de Playlist (campo owner, total de músicas etc).
 */
export interface SpotifyPlaylist {
  id: string;
  name: string;
  description: string;
  images: {
    url: string;
  }[];
  owner: {
    name: string;
  };
  tracks: {
    total: number;
  };
  external_urls: {
    spotify: string;
  };
  platform: "spotify";
  public: boolean;
}

/**
 * Versão “YouTube” de Playlist (campo canal, data de publicação).
 */
export interface YouTubePlaylist {
  id: string;
  name: string;
  description: string;
  images: {
    url: string;
  }[];
  owner: {
    name: string;
  };
  tracks: {
    total: number;
  };
  external_urls: {
    youtube: string;
  };
  platform: "youtube";
  channelTitle: string;
  publishedAt: string;
}

/**
 * Tipo unificado de Playlist, que pode ser SpotifyPlaylist ou YouTubePlaylist.
 */
export type Playlist = SpotifyPlaylist | YouTubePlaylist;

/**
 * Informações de paginação retornadas pelo endpoint de busca.
 */
export interface Pagination {
  total_albums: number;
  total_artists: number;
  total_tracks: number;
  total_playlists: number;
  limit: number;
  offset: number;
  has_next: boolean;
  has_previous: boolean;
  next_token?: string;
}

/**
 * Estrutura completa da resposta de busca (SearchResponse).
 */
export interface SearchResponse {
  artists: Artist[];
  albums: Album[];
  playlists: Playlist[];
  tracks: Track[];
  pagination: Pagination;
}

/**
 * === Processamento de URLs / Process-URLs (app/api/process-urls/route.ts e front-end) ===
 */

/**
 * Item genérico retornado após processar qualquer URL (track, playlist, album ou artist).
 */
export interface ProcessedItem {
  url: string;
  title: string;
  platform: "youtube" | "spotify";
  type: "track" | "playlist" | "album" | "artist";
  album?: string;
  duration?: string;
  thumbnail?: string;
  track_count?: number;
}

/**
 * Resposta completa do endpoint /process-urls (incluindo arrays separados).
 */
export interface ProcessedResponse {
  tracks: ProcessedItem[];
  playlists: ProcessedItem[];
  albums: ProcessedItem[];
  artists: ProcessedItem[];
  error?: string;
}

/**
 * === Progresso de Download (front-end) ===
 */

/**
 * Cada item exibido no componente de progresso de download.
 */
export interface DownloadProgressItem {
  url: string;
  status: "pending" | "downloading" | "completed" | "error";
  progress: number; // 0 a 100
  total_tracks?: number; // usado se estiver baixando playlists/albums
  completed_tracks: number;
  current_track?: string; // título da faixa que está baixando agora
  size?: string; // ex: "50MB"
  speed?: string; // ex: "500kB/s"
  eta?: string; // ex: "00:02:30"
  filename?: string; // nome do último arquivo baixado
  destination?: string; // pasta de destino
  errors: string[]; // lista de mensagens de erro (se houver)
}
