"use client";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ExternalLink, Download, Play, Volume2 } from "lucide-react";
import { PlatformBadge, Thumbnail } from "@/components/atoms";
import { Track } from "@/interfaces";

interface TrackCardProps {
  track: Track;
  isPlaying: boolean;
  onPlay: (track: Track) => void;
  onAddToQueue: (url: string) => void;
}

export function TrackCard({
  track,
  isPlaying,
  onPlay,
  onAddToQueue,
}: Readonly<TrackCardProps>) {
  const formatDuration = (durationMs: number): string => {
    const minutes = Math.floor(durationMs / 60000);
    const seconds = Math.floor((durationMs % 60000) / 1000);
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  };

  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString("pt-BR", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  const getThumbnailSrc = () => {
    if (track.platform === "spotify" && track.album?.images[0]?.url) {
      return track.album.images[0].url;
    }
    if (track.platform === "youtube" && track.thumbnail) {
      return track.thumbnail;
    }
    return undefined;
  };

  const getExternalUrl = () => {
    return track.platform === "spotify"
      ? track.external_urls.spotify
      : track.external_urls.youtube;
  };

  return (
    <div className="flex items-center justify-between p-4 border rounded-lg">
      <div className="flex items-center gap-4">
        <Thumbnail
          src={getThumbnailSrc()}
          alt={track.name}
          platform={track.platform}
          showPlatformBadge
        />
        <div>
          <h3 className="font-medium">{track.name}</h3>
          <p className="text-sm text-muted-foreground">
            {track.artists.map((a) => a.name).join(", ")}
            {track.platform === "spotify" &&
              track.album &&
              ` • ${track.album.name}`}
          </p>
          <div className="flex items-center gap-2 mt-1">
            {track.platform === "spotify" && track.duration_ms && (
              <p className="text-xs text-muted-foreground">
                {formatDuration(track.duration_ms)}
              </p>
            )}
            {track.platform === "youtube" && track.publishedAt && (
              <p className="text-xs text-muted-foreground">
                Publicado: {formatDate(track.publishedAt)}
              </p>
            )}
            {track.platform === "spotify" && track.popularity !== undefined && (
              <Badge variant="outline" className="text-xs">
                {track.popularity}% popularidade
              </Badge>
            )}
            {track.platform === "spotify" && track.explicit && (
              <Badge variant="destructive" className="text-xs">
                Explícito
              </Badge>
            )}
          </div>
        </div>
      </div>
      <div className="flex items-center gap-2">
        {((track.platform === "spotify" && track.preview_url) ||
          track.platform === "youtube") && (
          <Button
            size="sm"
            variant="outline"
            onClick={() => onPlay(track)}
            className={
              track.platform === "spotify" && isPlaying ? "bg-green-100" : ""
            }
          >
            {track.platform === "spotify" && isPlaying ? (
              <Volume2 className="h-4 w-4" />
            ) : (
              <Play className="h-4 w-4" />
            )}
          </Button>
        )}
        <Badge variant="default">Faixa</Badge>
        <PlatformBadge platform={track.platform} />
        <Button
          size="sm"
          variant="outline"
          onClick={() => window.open(getExternalUrl(), "_blank")}
        >
          <ExternalLink className="h-4 w-4" />
        </Button>
        <Button size="sm" onClick={() => onAddToQueue(getExternalUrl() || "")}>
          <Download className="h-4 w-4 mr-1" />
          Adicionar
        </Button>
      </div>
    </div>
  );
}
