"use client";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ExternalLink, Download } from "lucide-react";
import {
  PlatformBadge,
  PlaylistVisibilityBadge,
  Thumbnail,
} from "@/components/atoms";
import { Playlist } from "@/interfaces";

interface PlaylistCardProps {
  playlist: Playlist;
  onAddToQueue: (url: string) => void;
}

export function PlaylistCard({
  playlist,
  onAddToQueue,
}: Readonly<PlaylistCardProps>) {
  const formatDate = (dateString: string): string => {
    const date = new Date(dateString);
    return date.toLocaleDateString("pt-BR", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  const getExternalUrl = () => {
    return playlist.platform === "spotify"
      ? playlist.external_urls.spotify
      : playlist.external_urls.youtube;
  };

  return (
    <div className="flex items-center justify-between p-4 border rounded-lg">
      <div className="flex items-center gap-4">
        <Thumbnail
          src={playlist.images?.[0]?.url}
          alt={playlist.name}
          platform={playlist.platform}
          showPlatformBadge
        />
        <div className="flex-1">
          <h3 className="font-medium">{playlist.name}</h3>
          <p className="text-sm text-muted-foreground">
            Por {playlist.owner.name} • {playlist.tracks.total} músicas
          </p>
          {playlist.description && (
            <p className="text-xs text-muted-foreground mt-1 line-clamp-2">
              {playlist.description}
            </p>
          )}
          <div className="flex items-center gap-2 mt-1">
            {playlist.platform === "spotify" &&
              playlist.public !== undefined && (
                <PlaylistVisibilityBadge isPublic={playlist.public} />
              )}
            {playlist.platform === "youtube" && playlist.publishedAt && (
              <Badge variant="outline" className="text-xs">
                Criada: {formatDate(playlist.publishedAt)}
              </Badge>
            )}
          </div>
        </div>
      </div>
      <div className="flex items-center gap-2">
        <Badge variant="default">Playlist</Badge>
        <PlatformBadge platform={playlist.platform} />
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
