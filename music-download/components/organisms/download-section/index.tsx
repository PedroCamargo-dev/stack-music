"use client";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Download, Loader2, Eye, Terminal } from "lucide-react";
import { DownloadProgressItem } from "@/components/molecules";
import {
  DownloadProgressItem as IDownloadProgressItem,
  ProcessedItem,
} from "@/interfaces";
import Image from "next/image";

interface DownloadSectionProps {
  downloadUrls: string;
  downloadProgress: IDownloadProgressItem[];
  downloadLogs: string[];
  processedTracks: ProcessedItem[];
  processedPlaylists: ProcessedItem[];
  processedAlbums: ProcessedItem[];
  processedArtists: ProcessedItem[];
  workerCount: number;
  isDownloading: boolean;
  isProcessing: boolean;
  onDownloadUrlsChange: (urls: string) => void;
  onProcessUrls: () => void;
  onDownload: () => void;
  onClear: () => void;
}

export function DownloadSection({
  downloadUrls,
  downloadProgress,
  downloadLogs,
  processedTracks,
  processedPlaylists,
  processedAlbums,
  processedArtists,
  workerCount,
  isDownloading,
  isProcessing,
  onDownloadUrlsChange,
  onProcessUrls,
  onDownload,
  onClear,
}: Readonly<DownloadSectionProps>) {
  // dentro do componente DownloadSection, antes do retorno JSX
  const trackProgress = downloadProgress.filter((item) =>
    processedTracks.some((t) => t.url === item.url)
  );

  const playlistProgress = downloadProgress.filter((item) =>
    processedPlaylists.some((p) => p.url === item.url)
  );

  const albumProgress = downloadProgress.filter((item) =>
    processedAlbums.some((a) => a.url === item.url)
  );

  const artistProgress = downloadProgress.filter((item) =>
    processedArtists.some((ar) => ar.url === item.url)
  );

  // Opcional: caso haja URLs que não estejam em nenhuma das quatro listas processadas,
  // você pode agrupá-las em “outros”:
  const otherProgress = downloadProgress.filter(
    (item) =>
      !processedTracks.some((t) => t.url === item.url) &&
      !processedPlaylists.some((p) => p.url === item.url) &&
      !processedAlbums.some((a) => a.url === item.url) &&
      !processedArtists.some((ar) => ar.url === item.url)
  );

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Download className="h-5 w-5" />
            Download em Massa
          </CardTitle>
          <CardDescription>
            Baixe vários artistas, faixas ou playlists colando URLs (uma por
            linha)
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Textarea
            placeholder={`https://open.spotify.com/track/6habFhsOp2NvshLv26DqMb
https://www.youtube.com/watch?v=dQw4w9WgXcQ
https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M
https://www.youtube.com/playlist?list=PLrAXtmRdnEQy6nuLMt9xrTwCu1MxQX2x-
https://open.spotify.com/artist/4Z8W4fKeB5YxbusRsdQVPb`}
            value={downloadUrls}
            onChange={(e) => onDownloadUrlsChange(e.target.value)}
            rows={8}
            className="resize-none"
          />
          {downloadUrls.trim() && (
            <div className="flex justify-end">
              <Button
                variant="ghost"
                size="sm"
                onClick={onClear}
                className="text-muted-foreground hover:text-foreground"
              >
                Limpar Tudo
              </Button>
            </div>
          )}
          <div className="flex gap-2">
            <Button
              onClick={onProcessUrls}
              disabled={isProcessing}
              variant="outline"
              className="flex-1"
            >
              {isProcessing ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Processando...
                </>
              ) : (
                <>
                  <Eye className="mr-2 h-4 w-4" />
                  Processar URLs
                </>
              )}
            </Button>

            <Button
              onClick={onDownload}
              disabled={isDownloading}
              className="flex-1"
            >
              {isDownloading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Baixando...
                </>
              ) : (
                <>
                  <Download className="mr-2 h-4 w-4" />
                  Iniciar Download
                </>
              )}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Prévia das URLs Processadas */}
      {(processedTracks.length > 0 ||
        processedPlaylists.length > 0 ||
        processedAlbums.length > 0 ||
        processedArtists.length > 0) && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Eye className="h-5 w-5" />
              Prévia das URLs Processadas
            </CardTitle>
            <CardDescription>Prévia do que será baixado</CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* === TRACKS === */}
            {processedTracks.length > 0 && (
              <div>
                <h3 className="font-semibold mb-2">Faixas</h3>
                <div className="space-y-3">
                  {processedTracks.map((item) => (
                    <div
                      key={item.url}
                      className="flex items-center justify-between p-3 border rounded-lg"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 bg-muted rounded-lg overflow-hidden">
                          <Image
                            width={48}
                            height={48}
                            src={
                              item.thumbnail ??
                              "/placeholder.svg?height=48&width=48"
                            }
                            alt={item.title}
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <div>
                          <h4 className="font-medium text-sm">{item.title}</h4>
                          <p className="text-xs text-muted-foreground">
                            {item.platform} • {item.type}
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* === PLAYLISTS === */}
            {processedPlaylists.length > 0 && (
              <div>
                <h3 className="font-semibold mb-2">Playlists</h3>
                <div className="space-y-3">
                  {processedPlaylists.map((item) => (
                    <div
                      key={item.url}
                      className="flex items-center justify-between p-3 border rounded-lg"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 bg-muted rounded-lg overflow-hidden">
                          <Image
                            width={48}
                            height={48}
                            src={
                              item.thumbnail ??
                              "/placeholder.svg?height=48&width=48"
                            }
                            alt={item.title}
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <div>
                          <h4 className="font-medium text-sm">{item.title}</h4>
                          <p className="text-xs text-muted-foreground">
                            {item.platform} • {item.type}
                            {item.track_count &&
                              ` • ${item.track_count} faixas`}
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* === ALBUMS === */}
            {processedAlbums.length > 0 && (
              <div>
                <h3 className="font-semibold mb-2">Álbuns</h3>
                <div className="space-y-3">
                  {processedAlbums.map((item) => (
                    <div
                      key={item.url}
                      className="flex items-center justify-between p-3 border rounded-lg"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 bg-muted rounded-lg overflow-hidden">
                          <Image
                            width={48}
                            height={48}
                            src={
                              item.thumbnail ??
                              "/placeholder.svg?height=48&width=48"
                            }
                            alt={item.title}
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <div>
                          <h4 className="font-medium text-sm">{item.title}</h4>
                          <p className="text-xs text-muted-foreground">
                            {item.platform} • {item.type}
                            {item.track_count &&
                              ` • ${item.track_count} faixas`}
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* === ARTISTS === */}
            {processedArtists.length > 0 && (
              <div>
                <h3 className="font-semibold mb-2">Artistas</h3>
                <div className="space-y-3">
                  {processedArtists.map((item) => (
                    <div
                      key={item.url}
                      className="flex items-center justify-between p-3 border rounded-lg"
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 bg-muted rounded-lg overflow-hidden">
                          <Image
                            width={48}
                            height={48}
                            src={
                              item.thumbnail ??
                              "/placeholder.svg?height=48&width=48"
                            }
                            alt={item.title}
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <div>
                          <h4 className="font-medium text-sm">{item.title}</h4>
                          <p className="text-xs text-muted-foreground">
                            {item.platform} • {item.type}
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* === Informações dos Workers === */}
      {workerCount > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Terminal className="h-5 w-5" />
              Status do Download
            </CardTitle>
            <CardDescription>Número de workers: {workerCount}</CardDescription>
          </CardHeader>
        </Card>
      )}

      {/* === PROGRESSO: FAIXAS === */}
      {trackProgress.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Progresso de Faixas</CardTitle>
            <CardDescription>Download de faixas em andamento</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {trackProgress.map((item) => (
                <DownloadProgressItem key={item.url} item={item} />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* === PROGRESSO: PLAYLISTS === */}
      {playlistProgress.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Progresso de Playlists</CardTitle>
            <CardDescription>
              Download de playlists em andamento
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {playlistProgress.map((item) => (
                <DownloadProgressItem key={item.url} item={item} />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* === PROGRESSO: ÁLBUNS === */}
      {albumProgress.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Progresso de Álbuns</CardTitle>
            <CardDescription>Download de álbuns em andamento</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {albumProgress.map((item) => (
                <DownloadProgressItem key={item.url} item={item} />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* === PROGRESSO: ARTISTAS === */}
      {artistProgress.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Progresso de Artistas</CardTitle>
            <CardDescription>Download de artistas em andamento</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {artistProgress.map((item) => (
                <DownloadProgressItem key={item.url} item={item} />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* === PROGRESSO: OUTROS (caso existam URLs que não estavam em nenhuma lista processada) === */}
      {otherProgress.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Progresso de Outros</CardTitle>
            <CardDescription>
              Download de URLs não categorizadas
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {otherProgress.map((item) => (
                <DownloadProgressItem key={item.url} item={item} />
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Logs do Download */}
      {downloadLogs.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Terminal className="h-5 w-5" />
              Logs do Download
            </CardTitle>
            <CardDescription>Saída do download em tempo real</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="bg-black text-green-400 p-4 rounded-lg font-mono text-sm max-h-96 overflow-y-auto">
              {downloadLogs.map((log, index) => (
                <div key={index} className="mb-1">
                  {log}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
