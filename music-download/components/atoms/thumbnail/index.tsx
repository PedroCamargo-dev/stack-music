import { Music, Youtube } from "lucide-react";
import Image from "next/image";

interface ThumbnailProps {
  src?: string | null;
  alt?: string;
  platform?: "spotify" | "youtube";
  size?: "sm" | "md" | "lg";
  showPlatformBadge?: boolean;
}

export function Thumbnail({
  src,
  alt,
  platform,
  size = "md",
  showPlatformBadge = false,
}: Readonly<ThumbnailProps>) {
  const sizeClasses = {
    sm: "w-12 h-12",
    md: "w-16 h-16",
    lg: "w-20 h-20",
  };

  const imageDimension = size === "sm" ? 48 : size === "md" ? 64 : 80;

  return (
    <div
      className={`${sizeClasses[size]} bg-muted rounded-lg overflow-hidden relative`}
    >
      {src ? (
        <Image
          width={imageDimension}
          height={imageDimension}
          src={src ?? "/placeholder.svg"}
          alt={alt!}
          className="w-full h-full object-cover"
        />
      ) : (
        <div className="w-full h-full flex items-center justify-center bg-gray-200">
          {platform === "spotify" ? (
            <Music className="h-8 w-8 text-gray-400" />
          ) : (
            <Youtube className="h-8 w-8 text-gray-400" />
          )}
        </div>
      )}

      {showPlatformBadge && platform && (
        <div
          className={`absolute bottom-0 right-0 p-1 ${
            platform === "spotify" ? "bg-green-500" : "bg-red-500"
          } rounded-tl-md`}
        >
          {platform === "spotify" ? (
            <Music className="h-3 w-3 text-white" />
          ) : (
            <Youtube className="h-3 w-3 text-white" />
          )}
        </div>
      )}
    </div>
  );
}
