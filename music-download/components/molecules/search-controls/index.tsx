"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Search, Loader2 } from "lucide-react";
import { Dispatch, SetStateAction } from "react";

interface SearchControlsProps {
  searchQuery: string;
  searchType: string;
  searchLimit: number;
  isSearching: boolean;
  onSearchQueryChange: Dispatch<SetStateAction<string>>;
  onSearchTypeChange: Dispatch<SetStateAction<string>>;
  onSearchLimitChange: Dispatch<SetStateAction<number>>;
  onSearch: () => void;
}

export function SearchControls({
  searchQuery,
  searchType,
  searchLimit,
  isSearching,
  onSearchQueryChange,
  onSearchTypeChange,
  onSearchLimitChange,
  onSearch,
}: Readonly<SearchControlsProps>) {
  return (
    <div className="space-y-4">
      <div className="flex gap-4">
        <Input
          placeholder="Busque por artistas, músicas ou playlists..."
          value={searchQuery}
          onChange={(e) => onSearchQueryChange(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && onSearch()}
          className="flex-1"
        />
        <Select value={searchType} onValueChange={onSearchTypeChange}>
          <SelectTrigger className="w-48">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="artist,track,playlist,album">
              Todos os Tipos
            </SelectItem>
            <SelectItem value="artist">Apenas Artistas</SelectItem>
            <SelectItem value="track">Apenas Músicas</SelectItem>
            <SelectItem value="playlist">Apenas Playlists</SelectItem>
            <SelectItem value="album">Apenas Álbuns</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="flex gap-4 items-center">
        <div className="flex items-center gap-2">
          <label className="text-sm font-medium">Resultados por página:</label>
          <Select
            value={searchLimit.toString()}
            onValueChange={(value) =>
              onSearchLimitChange(Number.parseInt(value))
            }
          >
            <SelectTrigger className="w-20">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="5">5</SelectItem>
              <SelectItem value="10">10</SelectItem>
              <SelectItem value="20">20</SelectItem>
              <SelectItem value="50">50</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <Button onClick={onSearch} disabled={isSearching}>
          {isSearching ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              Buscando...
            </>
          ) : (
            <>
              <Search className="mr-2 h-4 w-4" />
              Buscar
            </>
          )}
        </Button>
      </div>
    </div>
  );
}
