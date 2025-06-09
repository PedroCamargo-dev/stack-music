import { ProgressBar, StatusBadge } from "@/components/atoms";
import { Clock, Loader2, CheckCircle, AlertCircle } from "lucide-react";
import { DownloadProgressItem as IDownloadProgressItem } from "@/interfaces";

interface DownloadProgressItemProps {
  item: IDownloadProgressItem & { error?: string };
}

type StatusIcon = "pending" | "downloading" | "completed" | "error";

export function DownloadProgressItem({
  item,
}: Readonly<DownloadProgressItemProps>) {
  const getStatusIcon = (status: StatusIcon) => {
    switch (status) {
      case "pending":
        return <Clock className="h-4 w-4" />;
      case "downloading":
        return <Loader2 className="h-4 w-4 animate-spin" />;
      case "completed":
        return <CheckCircle className="h-4 w-4" />;
      case "error":
        return <AlertCircle className="h-4 w-4" />;
      default:
        return <Clock className="h-4 w-4" />;
    }
  };

  return (
    <div className="border rounded-lg p-4">
      <div className="flex items-center justify-between mb-2">
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium truncate">{item.url}</p>
          {item.current_track && (
            <p className="text-xs text-muted-foreground">
              Atual: {item.current_track}
            </p>
          )}
          {item.destination && item.filename && (
            <p className="text-xs text-muted-foreground">
              {item.destination}/{item.filename}
            </p>
          )}
        </div>
        <div className="flex items-center gap-2">
          {getStatusIcon(item.status)}
          <StatusBadge status={item.status} />
        </div>
      </div>

      {item.status === "downloading" && (
        <>
          <ProgressBar progress={item.progress} className="mb-2" />
          <div className="flex justify-between text-xs text-muted-foreground">
            <span>
              {item.progress.toFixed(1)}%
              {item.total_tracks !== undefined &&
                item.completed_tracks !== undefined &&
                ` (${item.completed_tracks}/${item.total_tracks} faixas)`}
            </span>
            <div className="flex gap-4">
              {item.size && <span>{item.size}</span>}
              {item.speed && <span>{item.speed}</span>}
              {item.eta && <span>ETA {item.eta}</span>}
            </div>
          </div>
        </>
      )}

      {item.status === "completed" && (
        <p className="text-xs text-green-600 font-medium">
          Concluído ({item.progress.toFixed(0)}%)
        </p>
      )}

      {item.status === "error" && item.error && (
        <p className="text-sm text-red-500 mt-2">Erro: {item.error}</p>
      )}
    </div>
  );
}
