import { type NextRequest, NextResponse } from "next/server";

import { ProcessedItem, ProcessedResponse } from "@/interfaces";

export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const { urls }: { urls: string[] } = await request.json();

    if (!urls || !Array.isArray(urls) || urls.length === 0) {
      return NextResponse.json(
        { error: "URLs array is required" },
        { status: 400 }
      );
    }

    try {
      const response = await fetch(
        `${process.env.API_DOWNLOAD_URL}/process-urls`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ urls }),
          signal: AbortSignal.timeout(30000),
        }
      );

      if (!response.ok) {
        console.error(
          `Process URLs API responded with status: ${response.status}`
        );
        throw new Error(`API error: ${response.status}`);
      }

      const data: ProcessedResponse = await response.json();

      return NextResponse.json(data);
    } catch (fetchError) {
      console.error(
        "Failed to fetch from backend Go (/process-urls):",
        fetchError
      );

      // Montar fallback aleatório
      const fallbackTracks: ProcessedItem[] = [];
      const fallbackPlaylists: ProcessedItem[] = [];
      const fallbackAlbums: ProcessedItem[] = [];
      const fallbackArtists: ProcessedItem[] = [];

      for (const url of urls) {
        let platform: "youtube" | "spotify";
        let title: string;
        let type: "track" | "playlist" | "artist" | "album" = "track";
        let albumName: string | undefined = undefined;

        if (url.includes("youtube.com") || url.includes("youtu.be")) {
          platform = "youtube";

          if (url.includes("playlist")) {
            type = "playlist";
            title = `YouTube Playlist ${Math.floor(Math.random() * 1000)}`;
          } else {
            type = "track";
            title = `YouTube Video ${Math.floor(Math.random() * 1000)}`;
          }
        } else if (url.includes("spotify.com")) {
          platform = "spotify";

          if (url.includes("/playlist/")) {
            type = "playlist";
            title = `Spotify Playlist ${Math.floor(Math.random() * 1000)}`;
          } else if (url.includes("/artist/")) {
            type = "artist";
            title = `Spotify Artist ${Math.floor(Math.random() * 1000)}`;
          } else if (url.includes("/album/")) {
            type = "album";
            title = `Spotify Album ${Math.floor(Math.random() * 1000)}`;
            albumName = title;
          } else {
            type = "track";
            title = `Spotify Track ${Math.floor(Math.random() * 1000)}`;
          }
        } else {
          continue;
        }

        const item: ProcessedItem = {
          url,
          title,
          platform,
          type,
          album: albumName,
          duration: "3:45",
          thumbnail: "/placeholder.svg?height=64&width=64",
          track_count:
            type === "playlist" || type === "album"
              ? Math.floor(Math.random() * 50) + 10
              : undefined,
        };

        switch (type) {
          case "track":
            fallbackTracks.push(item);
            break;
          case "playlist":
            fallbackPlaylists.push(item);
            break;
          case "album":
            fallbackAlbums.push(item);
            break;
          case "artist":
            fallbackArtists.push(item);
            break;
        }
      }

      const fallbackData: ProcessedResponse = {
        tracks: fallbackTracks,
        playlists: fallbackPlaylists,
        albums: fallbackAlbums,
        artists: fallbackArtists,
        error: "Backend service unavailable – using fallback data",
      };

      return NextResponse.json(fallbackData);
    }
  } catch (error) {
    console.error("Process URLs (Next.js) error:", error);
    return NextResponse.json(
      { error: "Failed to process URLs" },
      { status: 500 }
    );
  }
}
