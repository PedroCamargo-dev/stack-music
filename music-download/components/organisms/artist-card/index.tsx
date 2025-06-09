"use client";

import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ExternalLink, Download } from "lucide-react";
import { PlatformBadge, Thumbnail } from "@/components/atoms";
import { Artist } from "@/interfaces";

interface ArtistCardProps {
  artist: Artist;
  onAddToQueue: (url: string) => void;
}

export function ArtistCard({
  artist,
  onAddToQueue,
}: Readonly<ArtistCardProps>) {
  const formatFollowers = (count: number): string => {
    if (count >= 1000000) {
      return `${(count / 1000000).toFixed(1)}M`;
    } else if (count >= 1000) {
      return `${(count / 1000).toFixed(1)}K`;
    }
    return count.toString();
  };

  return (
    <div className="flex items-center justify-between p-4 border rounded-lg">
      <div className="flex items-center gap-4">
        <Thumbnail
          src={artist.images?.[0]?.url}
          alt={artist.name}
          platform={artist.platform}
        />
        <div>
          <h3 className="font-medium text-lg">{artist.name}</h3>
          <p className="text-sm text-muted-foreground">
            {formatFollowers(artist.followers.total)} seguidores •{" "}
            {artist.popularity}% popularidade
          </p>
          <div className="flex gap-1 mt-1">
            {artist.genres.slice(0, 3).map((genre) => (
              <Badge key={genre} variant="outline" className="text-xs">
                {genre}
              </Badge>
            ))}
          </div>
        </div>
      </div>
      <div className="flex items-center gap-2">
        <Badge variant="secondary">Artista</Badge>
        <PlatformBadge platform={artist.platform} />
        <Button
          size="sm"
          variant="outline"
          onClick={() => window.open(artist.external_urls.spotify, "_blank")}
        >
          <ExternalLink className="h-4 w-4" />
        </Button>
        <Button
          size="sm"
          onClick={() => onAddToQueue(artist.external_urls.spotify)}
        >
          <Download className="h-4 w-4 mr-1" />
          Adicionar
        </Button>
      </div>
    </div>
  );
}
