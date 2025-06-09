import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, Music, ListMusic } from "lucide-react";
import { ArtistCard } from "../artist-card";
import { PlatformFilter } from "@/components/molecules";
import { PlaylistCard } from "../playlist-card";
import { TrackCard } from "../track-card";
import { AlbumCard } from "../album-card";
import { Artist, Track, Album, Playlist } from "@/interfaces";
import { Dispatch, SetStateAction } from "react";

interface SearchResultsProps {
  artists: Artist[];
  tracks: Track[];
  playlists: Playlist[];
  albums: Album[];
  platformFilter: "all" | "spotify" | "youtube";
  playingTrackId: string | null;
  totalArtists: number;
  totalTracks: number;
  totalPlaylists: number;
  totalAlbums: number;
  onPlatformFilterChange: Dispatch<
    SetStateAction<"spotify" | "youtube" | "all">
  >;
  onPlayTrack: (track: Track) => void;
  onAddToQueue: (url: string) => void;
}

export function SearchResults({
  artists,
  tracks,
  playlists,
  albums,
  platformFilter,
  playingTrackId,
  totalArtists,
  totalTracks,
  totalPlaylists,
  totalAlbums,
  onPlatformFilterChange,
  onPlayTrack,
  onAddToQueue,
}: Readonly<SearchResultsProps>) {
  const filteredTracks = tracks.filter((track) => {
    if (platformFilter === "all") return true;
    return track.platform === platformFilter;
  });

  const filteredPlaylists = playlists.filter((playlist) => {
    if (platformFilter === "all") return true;
    return playlist.platform === platformFilter;
  });

  const spotifyTrackCount = tracks.filter(
    (track) => track.platform === "spotify"
  ).length;
  const youtubeTrackCount = tracks.filter(
    (track) => track.platform === "youtube"
  ).length;

  const spotifyPlaylistCount = playlists.filter(
    (playlist) => playlist.platform === "spotify"
  ).length;
  const youtubePlaylistCount = playlists.filter(
    (playlist) => playlist.platform === "youtube"
  ).length;

  if (
    artists.length === 0 &&
    tracks.length === 0 &&
    playlists.length === 0 &&
    albums.length === 0
  ) {
    return null;
  }

  return (
    <div className="space-y-4">
      {/* Seção de Artistas */}
      {artists.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="h-5 w-5" />
              Artistas ({artists.length} de {totalArtists})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {artists.map((artist) => (
                <ArtistCard
                  key={artist.id}
                  artist={artist}
                  onAddToQueue={onAddToQueue}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Filtro de Plataforma */}
      {(tracks.length > 0 || playlists.length > 0) && (
        <PlatformFilter
          platformFilter={platformFilter}
          totalCount={tracks.length + playlists.length}
          spotifyCount={spotifyTrackCount + spotifyPlaylistCount}
          youtubeCount={youtubeTrackCount + youtubePlaylistCount}
          onFilterChange={onPlatformFilterChange}
        />
      )}

      {/* Seção de Álbuns */}
      {albums.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="h-5 w-5" />
              Álbuns ({albums.length} de {totalAlbums})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {albums.map((album) => (
                <AlbumCard
                  key={album.id}
                  album={album}
                  onAddToQueue={onAddToQueue}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Seção de Playlists */}
      {filteredPlaylists.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <ListMusic className="h-5 w-5" />
              Playlists ({filteredPlaylists.length} de{" "}
              {platformFilter === "all"
                ? totalPlaylists
                : platformFilter === "spotify"
                ? spotifyPlaylistCount
                : youtubePlaylistCount}
              )
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {filteredPlaylists.map((playlist) => (
                <PlaylistCard
                  key={`${playlist.platform}-${playlist.id}`}
                  playlist={playlist}
                  onAddToQueue={onAddToQueue}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Seção de Músicas */}
      {filteredTracks.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Music className="h-5 w-5" />
              Músicas ({filteredTracks.length} de{" "}
              {platformFilter === "all"
                ? totalTracks
                : platformFilter === "spotify"
                ? spotifyTrackCount
                : youtubeTrackCount}
              )
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {filteredTracks.map((track) => (
                <TrackCard
                  key={`${track.platform}-${track.id}`}
                  track={track}
                  isPlaying={playingTrackId === track.id}
                  onPlay={onPlayTrack}
                  onAddToQueue={onAddToQueue}
                />
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
