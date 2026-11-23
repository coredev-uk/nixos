{ pkgs }:

# Env for a Quickshell instance to play the wallpaper's aerial clip (config/lock/LockVideo.qml).
# Shared by the lock (home-manager) and the greeter (NixOS), which must pass the same nixpkgs as
# their quickshell so the patched Qt Multimedia matches. Patches live in overlays/default.nix.
{
  # Appends to the paths the quickshell wrapper already prepends.
  environment = ''
    # Patched Qt Multimedia.
    export NIXPKGS_QT6_QML_IMPORT_PATH=${pkgs.qtmultimedia-vaapi-layers}/${pkgs.qt6.qtbase.qtQmlPrefix}''${NIXPKGS_QT6_QML_IMPORT_PATH:+:$NIXPKGS_QT6_QML_IMPORT_PATH}
    export QT_PLUGIN_PATH=${pkgs.qtmultimedia-vaapi-layers}/${pkgs.qt6.qtbase.qtPluginPrefix}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}
    export QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
    # Nothing encodes; unset, Qt probes encoders at startup (~1 s before the first frame).
    export QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=
    # Searched first so only the NVIDIA driver is replaced.
    export LIBVA_DRIVERS_PATH=${pkgs.nvidia-vaapi-driver-git}/lib/dri:/run/opengl-driver/lib/dri
  '';
}
