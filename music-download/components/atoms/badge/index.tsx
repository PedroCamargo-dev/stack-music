import { Badge as ShadcnBadge } from "@/components/ui/badge";
import { Globe, Lock, BarChart3 } from "lucide-react";

interface PlatformBadgeProps {
  platform: "spotify" | "youtube";
}

export function PlatformBadge({ platform }: Readonly<PlatformBadgeProps>) {
  return (
    <ShadcnBadge
      variant="outline"
      className={platform === "spotify" ? "border-green-500" : "border-red-500"}
    >
      {platform === "spotify" ? "Spotify" : "YouTube"}
    </ShadcnBadge>
  );
}

interface StatusBadgeProps {
  status: "pending" | "downloading" | "completed" | "error";
}

export function StatusBadge({ status }: Readonly<StatusBadgeProps>) {
  const getStatusColor = (status: string) => {
    switch (status) {
      case "pending":
        return "bg-gray-500";
      case "downloading":
        return "bg-blue-500";
      case "completed":
        return "bg-green-500";
      case "error":
        return "bg-red-500";
      default:
        return "bg-gray-500";
    }
  };

  return <ShadcnBadge className={getStatusColor(status)}>{status}</ShadcnBadge>;
}

interface PlaylistVisibilityBadgeProps {
  isPublic: boolean;
}

export function PlaylistVisibilityBadge({
  isPublic,
}: Readonly<PlaylistVisibilityBadgeProps>) {
  return (
    <ShadcnBadge variant="outline" className="text-xs flex items-center gap-1">
      {isPublic ? <Globe className="h-3 w-3" /> : <Lock className="h-3 w-3" />}
      {isPublic ? "Public" : "Private"}
    </ShadcnBadge>
  );
}

interface TrackCountBadgeProps {
  count: number;
}

export function TrackCountBadge({ count }: Readonly<TrackCountBadgeProps>) {
  return (
    <ShadcnBadge variant="outline" className="flex items-center gap-1">
      <BarChart3 className="h-3 w-3" />
      {count}
    </ShadcnBadge>
  );
}
