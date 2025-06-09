"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Search } from "lucide-react";
import { Pagination, SearchControls } from "@/components/molecules";
import { DownloadSection, SearchResults } from "@/components/organisms";
import { useMusicDownload } from "@/hooks";

export function MusicDownload() {
  const {
    searchQuery,
    setSearchQuery,
    searchType,
    setSearchType,
    searchResults,
    isSearching,
    searchLimit,
    setSearchLimit,
    searchOffset,
    platformFilter,
    setPlatformFilter,

    playingTrackId,
    playPreview,

    downloadUrls,
    setDownloadUrls,
    downloadProgress,
    isDownloading,
    downloadLogs,
    workerCount,
    processedTracks,
    processedPlaylists,
    processedAlbums,
    processedArtists,
    isProcessing,

    handleSearch,
    addToDownloadQueue,
    handleProcessUrls,
    handleDownload,
    handleClear,

    getCurrentPage,
    getTotalPages,
    handlePageChange,
    handleNextPage,
    handlePreviousPage,
  } = useMusicDownload();

  return (
    <div className="container mx-auto p-6 max-w-6xl">
      <div className="space-y-6">
        <div className="text-center">
          <h1 className="text-3xl font-bold mb-2">Download de Músicas</h1>
          <p className="text-muted-foreground">
            Pesquise e baixe artistas, faixas e playlists de múltiplas
            plataformas
          </p>
        </div>

        <Tabs defaultValue="search" className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="search">Buscar Música</TabsTrigger>
            <TabsTrigger value="download">Download em Massa</TabsTrigger>
          </TabsList>

          <TabsContent value="search" className="space-y-4">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Search className="h-5 w-5" />
                  Buscar Música
                </CardTitle>
                <CardDescription>
                  Busque por artistas, faixas e playlists em várias plataformas
                </CardDescription>
              </CardHeader>
              <CardContent>
                <SearchControls
                  searchQuery={searchQuery}
                  searchType={searchType}
                  searchLimit={searchLimit}
                  isSearching={isSearching}
                  onSearchQueryChange={setSearchQuery}
                  onSearchTypeChange={setSearchType}
                  onSearchLimitChange={setSearchLimit}
                  onSearch={() => handleSearch(0)}
                />

                {/* Estatísticas da Busca */}
                {((searchResults.artists?.length || 0) > 0 ||
                  (searchResults.tracks?.length || 0) > 0 ||
                  (searchResults.playlists?.length || 0) > 0 ||
                  (searchResults.albums?.length || 0) > 0) && (
                  <div className="text-sm text-muted-foreground">
                    Mostrando {searchOffset + 1}-
                    {Math.min(
                      searchOffset + searchLimit,
                      (searchResults.pagination?.total_artists || 0) +
                        (searchResults.pagination?.total_tracks || 0) +
                        (searchResults.pagination?.total_playlists || 0) +
                        (searchResults.pagination?.total_albums || 0)
                    )}{" "}
                    de{" "}
                    {(searchResults.pagination?.total_artists || 0) +
                      (searchResults.pagination?.total_tracks || 0) +
                      (searchResults.pagination?.total_playlists || 0) +
                      (searchResults.pagination?.total_albums || 0)}{" "}
                    resultados
                  </div>
                )}
              </CardContent>
            </Card>

            <SearchResults
              artists={searchResults.artists}
              tracks={searchResults.tracks}
              playlists={searchResults.playlists}
              albums={searchResults.albums}
              platformFilter={platformFilter}
              playingTrackId={playingTrackId}
              totalArtists={searchResults.pagination.total_artists}
              totalTracks={searchResults.pagination.total_tracks}
              totalPlaylists={searchResults.pagination.total_playlists}
              totalAlbums={searchResults.pagination.total_albums}
              onPlatformFilterChange={setPlatformFilter}
              onPlayTrack={playPreview}
              onAddToQueue={addToDownloadQueue}
            />

            <Pagination
              currentPage={getCurrentPage()}
              totalPages={getTotalPages()}
              hasNext={searchResults.pagination.has_next}
              hasPrevious={searchResults.pagination.has_previous}
              isLoading={isSearching}
              onPageChange={handlePageChange}
              onNext={handleNextPage}
              onPrevious={handlePreviousPage}
            />
          </TabsContent>

          <TabsContent value="download" className="space-y-4">
            <DownloadSection
              downloadUrls={downloadUrls}
              downloadProgress={downloadProgress}
              downloadLogs={downloadLogs}
              processedTracks={processedTracks}
              processedPlaylists={processedPlaylists}
              processedAlbums={processedAlbums}
              processedArtists={processedArtists}
              workerCount={workerCount}
              isDownloading={isDownloading}
              isProcessing={isProcessing}
              onDownloadUrlsChange={setDownloadUrls}
              onProcessUrls={handleProcessUrls}
              onDownload={handleDownload}
              onClear={handleClear}
            />
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}
