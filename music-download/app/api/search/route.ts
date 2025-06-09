import {
  Album,
  Artist,
  Pagination,
  Playlist,
  SearchResponse,
  SpotifyPlaylist,
  SpotifyTrack,
  Track,
  YouTubePlaylist,
  YouTubeTrack,
} from "@/interfaces";
import fs from "fs";
import { NextRequest, NextResponse } from "next/server";
import path from "path";

type CombinedRawResponse = {
  spotify: {
    albums?: Array<{
      id: string;
      name: string;
      album_type: string;
      artists?: Array<{
        name: string;
        external_urls: { spotify: string };
      }>;
      release_date: string;
      total_tracks: number;
      images?: Array<{ url: string }>;
      external_urls: { spotify: string };
    }>;
    artists?: Array<{
      id: string;
      name: string;
      genres: string[];
      popularity: number;
      followers: { total: number };
      images?: Array<{ url: string }>;
      external_urls: { spotify: string };
    }>;
    tracks?: Array<{
      id: string;
      name: string;
      album: {
        name: string;
        images?: Array<{ url: string }>;
      };
      artists?: Array<{ name: string }>;
      duration_ms: number;
      external_urls: { spotify: string };
      popularity: number;
      explicit: boolean;
      preview_url: string | null;
    }>;
    playlists?: Array<{
      id: string;
      name: string;
      description: string;
      images?: Array<{ url: string }>;
      owner: { display_name: string };
      tracks: { total: number };
      external_urls: { spotify: string };
      public: boolean;
    }>;
    pagination?: {
      has_next_album: boolean;
      has_previous_album: boolean;
      has_next_artist: boolean;
      has_previous_artist: boolean;
      has_next_track: boolean;
      has_previous_track: boolean;
      has_next_playlist: boolean;
      has_previous_playlist: boolean;
      total_albums: number;
      total_artists: number;
      total_tracks: number;
      total_playlists: number;
    };
  };
  youtube?: {
    playlists?: Array<{
      id: { playlistId: string };
      snippet: {
        title: string;
        description: string;
        channelTitle: string;
        publishedAt: string;
        thumbnails: { high: { url: string } };
      };
    }>;
    videos?: Array<{
      id: { videoId: string };
      snippet: {
        title: string;
        channelTitle: string;
        publishedAt: string;
        thumbnails: { high: { url: string } };
      };
    }>;
    nextPageToken?: string;
  };
};

export async function GET(request: NextRequest): Promise<NextResponse> {
  try {
    const url = new URL(request.url);
    const searchParams = url.searchParams;
    const query = searchParams.get("query");
    const typeParam = searchParams.get("type") ?? "artist,track,playlist,album";
    const limitParam = searchParams.get("limit") ?? "10";
    const offsetParam = searchParams.get("offset") ?? "0";
    const youtubeType = searchParams.get("youtube_type") ?? "video,playlist";
    const youtubeMaxResults = searchParams.get("maxResults") ?? "10";
    const pageTokenParam = searchParams.get("pageToken") ?? "";

    if (!query) {
      return NextResponse.json(
        { error: "Query parameter is required" },
        { status: 400 }
      );
    }

    const params = new URLSearchParams({
      query,
      type: typeParam,
      limit: limitParam,
      offset: offsetParam,
      youtube_type: youtubeType,
      maxResults: youtubeMaxResults,
    });
    if (pageTokenParam) {
      params.append("pageToken", pageTokenParam);
    }

    const fetchResponse = await fetch(
      `${process.env.API_DOWNLOAD_URL}/search?${params.toString()}`
    );
    if (!fetchResponse.ok) {
      return NextResponse.json(
        { error: `Search service returned ${fetchResponse.status}` },
        { status: fetchResponse.status }
      );
    }

    const combinedResponse: CombinedRawResponse = await fetchResponse.json();

    // Opcional: gravar para debug local (em dev somente)
    try {
      const debugPath = path.join(process.cwd(), "combinedResponse.json");
      fs.writeFileSync(debugPath, JSON.stringify(combinedResponse, null, 2));
    } catch {
      // ignorar falha de escrita em produção
    }

    // === Montar objetos de album (Spotify) ===
    const rawAlbums = combinedResponse.spotify.albums ?? [];
    const albums: Album[] = rawAlbums.map((album) => ({
      id: album.id,
      name: album.name,
      album_type: album.album_type,
      artists: (album.artists ?? []).map((artist) => ({
        name: artist.name,
        external_urls: { spotify: artist.external_urls.spotify },
      })),
      release_date: album.release_date,
      total_tracks: album.total_tracks,
      images: (album.images ?? []).map((img) => ({ url: img.url })),
      external_urls: { spotify: album.external_urls.spotify },
      platform: "spotify",
    }));

    // === Montar objetos de artist (Spotify) ===
    const rawArtists = combinedResponse.spotify.artists ?? [];
    const artists: Artist[] = rawArtists.map((artist) => ({
      id: artist.id,
      name: artist.name,
      genres: artist.genres,
      popularity: artist.popularity,
      followers: { total: artist.followers.total },
      images: (artist.images ?? []).map((img) => ({ url: img.url })),
      external_urls: { spotify: artist.external_urls.spotify },
      platform: "spotify",
    }));

    // === Montar objetos de track (Spotify) ===
    const rawSpotifyTracks = combinedResponse.spotify.tracks ?? [];
    const spotifyTracks: SpotifyTrack[] = rawSpotifyTracks.map((track) => ({
      id: track.id,
      name: track.name,
      album: {
        name: track.album.name,
        images: (track.album.images ?? []).map((img) => ({ url: img.url })),
      },
      artists: (track.artists ?? []).map((artist) => ({ name: artist.name })),
      duration_ms: track.duration_ms,
      external_urls: { spotify: track.external_urls.spotify },
      popularity: track.popularity,
      explicit: track.explicit,
      preview_url: track.preview_url,
      platform: "spotify",
    }));

    // === Montar objetos de track (YouTube) ===
    let youtubeTracks: YouTubeTrack[] = [];
    if (
      combinedResponse.youtube &&
      Array.isArray(combinedResponse.youtube.videos)
    ) {
      youtubeTracks = combinedResponse.youtube.videos.map((video) => ({
        id: video.id.videoId,
        name: video.snippet.title,
        artists: [{ name: video.snippet.channelTitle }],
        external_urls: {
          youtube: `https://www.youtube.com/watch?v=${video.id.videoId}`,
        },
        platform: "youtube",
        thumbnail: video.snippet.thumbnails.high.url,
        channelTitle: video.snippet.channelTitle,
        publishedAt: video.snippet.publishedAt,
      }));
    }

    const tracks: Track[] = [...spotifyTracks, ...youtubeTracks];

    // === Montar objetos de playlist (Spotify) ===
    const rawSpotifyPlaylists = combinedResponse.spotify.playlists ?? [];
    const spotifyPlaylists: SpotifyPlaylist[] = rawSpotifyPlaylists.map(
      (playlist) => ({
        id: playlist.id,
        name: playlist.name,
        description: playlist.description,
        images: (playlist.images ?? []).map((img) => ({ url: img.url })),
        owner: { name: playlist.owner.display_name },
        tracks: { total: playlist.tracks.total },
        external_urls: { spotify: playlist.external_urls.spotify },
        platform: "spotify",
        public: playlist.public,
      })
    );

    // === Montar objetos de playlist (YouTube) ===
    let youtubePlaylists: YouTubePlaylist[] = [];
    if (Array.isArray(combinedResponse.youtube?.playlists)) {
      youtubePlaylists = combinedResponse.youtube.playlists.map((playlist) => ({
        id: playlist.id.playlistId,
        name: playlist.snippet.title,
        description: playlist.snippet.description,
        images: [{ url: playlist.snippet.thumbnails.high.url }],
        owner: { name: playlist.snippet.channelTitle },
        tracks: { total: 0 }, // YouTube Search não retorna total real
        external_urls: {
          youtube: `https://www.youtube.com/playlist?list=${playlist.id.playlistId}`,
        },
        platform: "youtube",
        channelTitle: playlist.snippet.channelTitle,
        publishedAt: playlist.snippet.publishedAt,
      }));
    }

    const playlists: Playlist[] = [...spotifyPlaylists, ...youtubePlaylists];

    // === Paginação unificada ===
    const spotifyPagination = combinedResponse.spotify.pagination ?? {
      has_next_album: false,
      has_previous_album: false,
      has_next_artist: false,
      has_previous_artist: false,
      has_next_track: false,
      has_previous_track: false,
      has_next_playlist: false,
      has_previous_playlist: false,
      total_albums: 0,
      total_artists: 0,
      total_playlists: 0,
      total_tracks: 0,
    };

    const youtubeTotalResults: number = Array.isArray(
      combinedResponse.youtube?.videos
    )
      ? combinedResponse.youtube.videos.length
      : 0;
    const youtubePlaylistCount: number = Array.isArray(
      combinedResponse.youtube?.playlists
    )
      ? combinedResponse.youtube.playlists.length
      : 0;

    const pagination: Pagination = {
      total_albums: spotifyPagination.total_albums,
      total_artists: spotifyPagination.total_artists,
      total_tracks: spotifyPagination.total_tracks + youtubeTotalResults,
      total_playlists: spotifyPagination.total_playlists + youtubePlaylistCount,
      limit: Number(limitParam),
      offset: Number(offsetParam),
      has_next:
        spotifyPagination.has_next_album ||
        spotifyPagination.has_next_artist ||
        spotifyPagination.has_next_playlist ||
        spotifyPagination.has_next_track ||
        (combinedResponse.youtube?.videos?.length ?? 0) > 0,
      has_previous:
        spotifyPagination.has_previous_album ||
        spotifyPagination.has_previous_artist ||
        spotifyPagination.has_previous_playlist ||
        spotifyPagination.has_previous_track ||
        Number(offsetParam) > 0,
      next_token: combinedResponse.youtube?.nextPageToken,
    };

    const searchResponse: SearchResponse = {
      artists,
      albums,
      playlists,
      tracks,
      pagination,
    };

    return NextResponse.json(searchResponse);
  } catch (error) {
    console.error("Search error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
