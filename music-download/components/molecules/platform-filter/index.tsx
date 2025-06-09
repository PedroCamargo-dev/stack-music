"use client";

import { Button } from "@/components/ui/button";
import { Music, Youtube } from "lucide-react";
import { Dispatch, SetStateAction } from "react";

interface PlatformFilterProps {
  platformFilter: "all" | "spotify" | "youtube";
  totalCount: number;
  spotifyCount: number;
  youtubeCount: number;
  onFilterChange: Dispatch<SetStateAction<"all" | "spotify" | "youtube">>;
}

export function PlatformFilter({
  platformFilter,
  totalCount,
  spotifyCount,
  youtubeCount,
  onFilterChange,
}: Readonly<PlatformFilterProps>) {
  return (
    <div className="flex justify-center gap-2">
      <Button
        variant={platformFilter === "all" ? "default" : "outline"}
        size="sm"
        onClick={() => onFilterChange("all")}
      >
        Todas as Plataformas ({totalCount})
      </Button>
      <Button
        variant={platformFilter === "spotify" ? "default" : "outline"}
        size="sm"
        onClick={() => onFilterChange("spotify")}
        className="flex items-center gap-1"
        disabled={spotifyCount === 0}
      >
        <Music className="h-4 w-4" />
        Spotify ({spotifyCount})
      </Button>
      <Button
        variant={platformFilter === "youtube" ? "default" : "outline"}
        size="sm"
        onClick={() => onFilterChange("youtube")}
        className="flex items-center gap-1"
        disabled={youtubeCount === 0}
      >
        <Youtube className="h-4 w-4" />
        YouTube ({youtubeCount})
      </Button>
    </div>
  );
}
