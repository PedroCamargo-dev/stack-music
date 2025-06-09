import { PlatformBadge, Thumbnail } from "@/components/atoms";
import { Download, ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Album } from "@/interfaces";

interface AlbumCardProps {
  album: Album;
  onAddToQueue: (url: string) => void;
}

export function AlbumCard({ album, onAddToQueue }: Readonly<AlbumCardProps>) {
  return (
    <div className="flex items-center justify-between p-4 border rounded-lg">
      <div className="flex items-center gap-4">
        <Thumbnail
          src={album.images?.[0]?.url}
          alt={album.name}
          platform={album.platform}
        />
        <div>
          <h3 className="font-medium text-lg">{album.name}</h3>
          <p className="text-sm text-muted-foreground">
            {album.artists.map((a) => a.name).join(", ")} •{" "}
            {album.release_date.slice(0, 4)}
          </p>
          <div className="flex gap-1 mt-1">
            <Badge variant="outline" className="text-xs">
              {album.total_tracks} faixas
            </Badge>
          </div>
        </div>
      </div>
      <div className="flex items-center gap-2">
        <Badge variant="secondary">Álbuns</Badge>
        <PlatformBadge platform={album.platform} />
        <Button
          size="sm"
          variant="outline"
          onClick={() => window.open(album.external_urls.spotify, "_blank")}
        >
          <ExternalLink className="h-4 w-4" />
        </Button>
        <Button
          size="sm"
          onClick={() => onAddToQueue(album.external_urls.spotify)}
        >
          <Download className="h-4 w-4 mr-1" />
          Adicionar
        </Button>
      </div>
    </div>
  );
}
