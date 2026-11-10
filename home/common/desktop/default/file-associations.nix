_:
let
  archiveManager = [ "org.gnome.FileRoller.desktop" ];
  fileBrowser = [ "org.gnome.Nautilus.desktop" ];
  imageViewer = [ "org.gnome.Loupe.desktop" ];
  videoPlayer = [ "mpv.desktop" ];
  documentViewer = [ "org.gnome.Papers.desktop" ];
in
{
  # XDG MIME types
  associations = {
    "inode/directory" = fileBrowser;

    # Audio and video (mimeapps.list has no wildcards, so the common types are listed)
    "audio/mpeg" = videoPlayer;
    "audio/mp4" = videoPlayer;
    "audio/aac" = videoPlayer;
    "audio/flac" = videoPlayer;
    "audio/x-flac" = videoPlayer;
    "audio/ogg" = videoPlayer;
    "audio/opus" = videoPlayer;
    "audio/wav" = videoPlayer;
    "audio/x-wav" = videoPlayer;
    "audio/webm" = videoPlayer;
    "audio/x-matroska" = videoPlayer;
    "audio/x-ms-wma" = videoPlayer;
    "audio/x-aiff" = videoPlayer;
    "audio/x-mpegurl" = videoPlayer;
    "video/mp4" = videoPlayer;
    "video/x-matroska" = videoPlayer;
    "video/webm" = videoPlayer;
    "video/mpeg" = videoPlayer;
    "video/ogg" = videoPlayer;
    "video/quicktime" = videoPlayer;
    "video/x-msvideo" = videoPlayer;
    "video/x-flv" = videoPlayer;
    "video/x-ms-wmv" = videoPlayer;
    "video/3gpp" = videoPlayer;
    "video/mp2t" = videoPlayer;

    # "application/json" = browser;
    "application/pdf" = documentViewer;

    # Archives / compressed files
    "application/x-7z-compressed" = archiveManager;
    "application/x-7z-compressed-tar" = archiveManager;
    "application/x-bzip" = archiveManager;
    "application/x-bzip-compressed-tar" = archiveManager;
    "application/x-compress" = archiveManager;
    "application/x-compressed-tar" = archiveManager;
    "application/x-cpio" = archiveManager;
    "application/x-gzip" = archiveManager;
    "application/x-lha" = archiveManager;
    "application/x-lzip" = archiveManager;
    "application/x-lzip-compressed-tar" = archiveManager;
    "application/x-lzma" = archiveManager;
    "application/x-lzma-compressed-tar" = archiveManager;
    "application/x-tar" = archiveManager;
    "application/x-tarz" = archiveManager;
    "application/x-xar" = archiveManager;
    "application/x-xz" = archiveManager;
    "application/x-xz-compressed-tar" = archiveManager;
    "application/zip" = archiveManager;
    "application/gzip" = archiveManager;
    "application/bzip2" = archiveManager;
    "application/vnd.rar" = archiveManager;

    # Images
    "image/jpeg" = imageViewer;
    "image/png" = imageViewer;
    "image/gif" = imageViewer;
    "image/webp" = imageViewer;
    "image/tiff" = imageViewer;
    "image/x-tga" = imageViewer;
    "image/vnd-ms.dds" = imageViewer;
    "image/x-dds" = imageViewer;
    "image/bmp" = imageViewer;
    "image/vnd.microsoft.icon" = imageViewer;
    "image/vnd.radiance" = imageViewer;
    "image/x-exr" = imageViewer;
    "image/x-portable-bitmap" = imageViewer;
    "image/x-portable-graymap" = imageViewer;
    "image/x-portable-pixmap" = imageViewer;
    "image/x-portable-anymap" = imageViewer;
    "image/x-qoi" = imageViewer;
    "image/svg+xml" = imageViewer;
    "image/svg+xml-compressed" = imageViewer;
    "image/avif" = imageViewer;
    "image/heic" = imageViewer;
    "image/jxl" = imageViewer;
  };
}
