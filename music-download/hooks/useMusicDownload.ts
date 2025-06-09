import { useState } from "react";
import { toast } from "sonner";
import {
  SearchResponse,
  ProcessedItem,
  DownloadProgressItem as DPI,
  YouTubeTrack,
  SpotifyTrack,
  Track,
  ProcessedResponse,
} from "@/interfaces";

interface DownloadProgressInternal extends DPI {
  // já cobre todos os campos de DownloadProgressItem
}

function useMusicDownload() {
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [searchType, setSearchType] = useState<string>(
    "artist,track,playlist,album"
  );
  const [searchResults, setSearchResults] = useState<SearchResponse>({
    artists: [],
    tracks: [],
    playlists: [],
    albums: [],
    pagination: {
      total_albums: 0,
      total_artists: 0,
      total_tracks: 0,
      total_playlists: 0,
      limit: 10,
      offset: 0,
      has_next: false,
      has_previous: false,
    },
  });
  const [isSearching, setIsSearching] = useState<boolean>(false);
  const [searchLimit, setSearchLimit] = useState<number>(10);
  const [searchOffset, setSearchOffset] = useState<number>(0);
  const [platformFilter, setPlatformFilter] = useState<
    "all" | "spotify" | "youtube"
  >("all");

  const [currentAudio, setCurrentAudio] = useState<HTMLAudioElement | null>(
    null
  );
  const [playingTrackId, setPlayingTrackId] = useState<string | null>(null);

  const [downloadUrls, setDownloadUrls] = useState<string>("");
  const [downloadProgress, setDownloadProgress] = useState<
    DownloadProgressInternal[]
  >([]);
  const [isDownloading, setIsDownloading] = useState<boolean>(false);
  const [downloadLogs, setDownloadLogs] = useState<string[]>([]);
  const [workerCount, setWorkerCount] = useState<number>(0);

  const [processedTracks, setProcessedTracks] = useState<ProcessedItem[]>([]);
  const [processedPlaylists, setProcessedPlaylists] = useState<ProcessedItem[]>(
    []
  );
  const [processedAlbums, setProcessedAlbums] = useState<ProcessedItem[]>([]);
  const [processedArtists, setProcessedArtists] = useState<ProcessedItem[]>([]);
  const [isProcessing, setIsProcessing] = useState<boolean>(false);

  const handleSearch = async (newOffset?: number) => {
    if (!searchQuery.trim()) {
      toast.error("Consulta de busca obrigatória", {
        description: "Por favor, insira um termo de busca.",
      });
      return;
    }

    const offset = newOffset ?? searchOffset;
    setIsSearching(true);

    try {
      const params = new URLSearchParams({
        query: searchQuery,
        type: searchType,
        limit: searchLimit.toString(),
        offset: offset.toString(),
      });

      const response = await fetch(`/api/search?${params}`);
      const data: SearchResponse = await response.json();

      if (response.ok) {
        setSearchResults(data);
        setSearchOffset(offset);

        const totalResults =
          (data.artists?.length ?? 0) +
          (data.tracks?.length ?? 0) +
          (data.playlists?.length ?? 0);
        toast.success("Busca concluída", {
          description: `Encontrados ${totalResults} resultados nesta página.`,
        });
      } else {
        throw new Error("Falha na busca");
      }
    } catch (error) {
      toast.error("Falha na busca", {
        description: error instanceof Error ? error.message : "Ocorreu um erro",
      });
    } finally {
      setIsSearching(false);
    }
  };

  const playPreview = (track: Track) => {
    if (track.platform === "spotify" && !(track as SpotifyTrack).preview_url) {
      toast.error("Prévia não disponível", {
        description: "Esta faixa não possui prévia disponível.",
      });
      return;
    }

    if (currentAudio) {
      currentAudio.pause();
      currentAudio.currentTime = 0;
    }

    if (playingTrackId === track.id) {
      setPlayingTrackId(null);
      setCurrentAudio(null);
      return;
    }

    if (track.platform === "spotify") {
      const spotifyTrack = track as SpotifyTrack;
      if (spotifyTrack.preview_url) {
        const audio = new Audio(spotifyTrack.preview_url);
        audio.play();
        setCurrentAudio(audio);
        setPlayingTrackId(spotifyTrack.id);

        audio.onended = () => {
          setPlayingTrackId(null);
          setCurrentAudio(null);
        };

        toast.success("Reproduzindo prévia", {
          description: `${spotifyTrack.name} - prévia de 30 segundos`,
        });
      }
    } else if (track.platform === "youtube") {
      window.open((track as YouTubeTrack).external_urls.youtube, "_blank");
    }
  };

  const addToDownloadQueue = (url: string) => {
    const currentUrls = downloadUrls.split("\n").filter((u) => u.trim());
    if (!currentUrls.includes(url)) {
      setDownloadUrls((prev) => (prev ? `${prev}\n${url}` : url));
      toast.success("Adicionado à fila", {
        description: "URL adicionada à fila de download.",
      });
    }
  };

  const handleProcessUrls = async () => {
    if (!downloadUrls.trim()) {
      toast.error("Nenhuma URL fornecida", {
        description: "Por favor, insira URLs para processar.",
      });
      return;
    }

    setIsProcessing(true);
    const urlsToProcess = downloadUrls
      .split("\n")
      .map((u) => u.trim())
      .filter((u) => !!u);

    try {
      const response = await fetch("/api/process-urls", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ urls: urlsToProcess }),
      });

      const data: ProcessedResponse = await response.json();

      if (response.ok) {
        setProcessedTracks(data.tracks || []);
        setProcessedPlaylists(data.playlists || []);
        setProcessedAlbums(data.albums || []);
        setProcessedArtists(data.artists || []);

        if (data.error) {
          toast.warning("Processamento alternativo", {
            description: data.error,
          });
        } else {
          const totalItems =
            (data.tracks?.length || 0) +
            (data.playlists?.length || 0) +
            (data.albums?.length || 0) +
            (data.artists?.length || 0);

          toast.success("URLs processadas com sucesso", {
            description: `Processados ${totalItems} itens no total.`,
          });
        }
      } else {
        throw new Error(data.error ?? "Falha ao processar URLs");
      }
    } catch (error) {
      toast.error("Falha ao processar URLs", {
        description:
          error instanceof Error ? error.message : "Ocorreu um erro inesperado",
      });
    } finally {
      setIsProcessing(false);
    }
  };

  const handleDownload = async () => {
    if (!downloadUrls.trim()) {
      toast.error("Nenhuma URL fornecida", {
        description: "Por favor, insira URLs para baixar.",
      });
      return;
    }

    setIsDownloading(true);
    const urls = downloadUrls.split("\n").filter((u) => u.trim());
    const initialProgress: DownloadProgressInternal[] = urls.map((url) => ({
      url: url.trim(),
      status: "pending",
      progress: 0,
      total_tracks: undefined,
      completed_tracks: 0,
      current_track: undefined,
      size: undefined,
      speed: undefined,
      eta: undefined,
      filename: undefined,
      destination: undefined,
      errors: [],
    }));
    setDownloadProgress(initialProgress);
    setDownloadLogs([]);
    setWorkerCount(0);

    const toastId = toast.loading("Iniciando downloads...", {
      description: `Preparando para baixar ${urls.length} tarefas`,
    });

    try {
      const response = await fetch("/api/download", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ urls }),
      });
      if (!response.ok) throw new Error("Falha na solicitação de download");

      const reader = response.body?.getReader();
      const decoder = new TextDecoder();
      if (!reader) {
        throw new Error("Sem corpo de resposta do stream");
      }

      let buffer = "";

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split("\n");
        buffer = lines.pop() ?? "";

        for (const rawLine of lines) {
          const line = rawLine.trim();
          if (!line) continue;

          setDownloadLogs((prev) => [...prev, line]);

          if (line.startsWith("Number of workers:")) {
            const count = parseInt(line.split(":")[1].trim(), 10);
            if (!isNaN(count)) setWorkerCount(count);
            continue;
          }

          if (line === "All downloads completed") {
            setDownloadProgress((prev) =>
              prev.map((item) => {
                if (item.status !== "completed" && item.status !== "error") {
                  return {
                    ...item,
                    status: "completed",
                    progress: 100,
                    current_track: undefined,
                  };
                }
                return item;
              })
            );
            continue;
          }

          const urlMsgMatch = line.match(/^\[(https?:\/\/[^\]]+)\]\s*(.*)$/);
          if (!urlMsgMatch) {
            continue;
          }
          const msgUrl = urlMsgMatch[1];
          const message = urlMsgMatch[2];

          setDownloadProgress((prev) =>
            prev.map((item) => {
              if (item.url !== msgUrl) return item;

              let status = item.status;
              let total_tracks = item.total_tracks;
              let completed_tracks = item.completed_tracks;
              let current_track = item.current_track;
              const size = item.size;
              const speed = item.speed;
              const eta = item.eta;
              const filename = item.filename;
              const destination = item.destination;
              let errors = item.errors;

              // Reduce complexity by splitting into helpers
              const updateProgress = (completed: number, total?: number) => {
                if (total) {
                  const prog = (completed / total) * 100;
                  return Math.min(prog, 100);
                }
                return item.progress;
              };

              if (message.startsWith("Processing query:")) {
                status = "downloading";
              } else if (message.startsWith("Found ")) {
                const foundSongsRegex = /^Found (\d+) songs/;
                const m = foundSongsRegex.exec(message);
                if (m) {
                  total_tracks = parseInt(m[1], 10);
                }
              } else if (message.startsWith('Downloaded "')) {
                const downloadedRegex = /^Downloaded "([^"]+)"/;
                const m = downloadedRegex.exec(message);
                if (m) {
                  current_track = m[1];
                  completed_tracks += 1;
                  if (total_tracks) {
                    item.progress = updateProgress(
                      completed_tracks,
                      total_tracks
                    );
                  } else {
                    status = "completed";
                    item.progress = 100;
                  }
                }
              } else if (message.startsWith("Skipping")) {
                const skippingRegex = /^Skipping\s+(.+?)\s+\(/;
                const m = skippingRegex.exec(message);
                if (m) current_track = m[1];
                completed_tracks += 1;
                if (total_tracks) {
                  item.progress = updateProgress(
                    completed_tracks,
                    total_tracks
                  );
                }
              } else if (
                message.startsWith("Download completed successfully for URL")
              ) {
                status = "completed";
                item.progress = 100;
                current_track = undefined;
              } else if (message.startsWith("FFmpegError")) {
                const m = message.replace(/^FFmpegError:\s*/, "");
                errors = [...errors, m];
              }

              return {
                ...item,
                status,
                total_tracks,
                completed_tracks,
                current_track,
                size,
                speed,
                eta,
                filename,
                destination,
                errors,
              };
            })
          );
        }
      }

      toast.success("Downloads concluídos", {
        id: toastId,
        description: `Todos os downloads finalizaram.`,
      });
      setDownloadUrls("");
    } catch (err) {
      toast.error("Falha no processo de download", {
        id: toastId,
        description: err instanceof Error ? err.message : "Erro desconhecido",
      });
    } finally {
      setIsDownloading(false);
    }
  };

  const handleClear = () => {
    setDownloadUrls("");
    setProcessedTracks([]);
    setProcessedPlaylists([]);
    setProcessedAlbums([]);
    setProcessedArtists([]);
    setDownloadProgress([]);
    setDownloadLogs([]);
    setWorkerCount(0);
  };

  const getCurrentPage = (): number =>
    Math.floor(searchOffset / searchLimit) + 1;
  const getTotalPages = (): number => {
    const totalItems = Math.max(
      searchResults.pagination.total_artists,
      searchResults.pagination.total_tracks,
      searchResults.pagination.total_playlists,
      searchResults.pagination.total_albums
    );
    return Math.ceil(totalItems / searchLimit);
  };

  const handlePageChange = (page: number) => {
    const newOffset = (page - 1) * searchLimit;
    handleSearch(newOffset);
  };

  const handleNextPage = () => {
    const newOffset = searchOffset + searchLimit;
    handleSearch(newOffset);
  };

  const handlePreviousPage = () => {
    const newOffset = Math.max(0, searchOffset - searchLimit);
    handleSearch(newOffset);
  };

  return {
    searchQuery,
    setSearchQuery,
    searchType,
    setSearchType,
    searchResults,
    isSearching,
    searchLimit,
    setSearchLimit,
    searchOffset,
    setSearchOffset,
    platformFilter,
    setPlatformFilter,
    currentAudio,
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
  };
}

export { useMusicDownload };
