{ pkgs }:

# What a Quickshell instance needs to play the wallpaper's aerial clip (config/lock/LockVideo.qml):
# shared by the lock (default.nix, home-manager) and the greeter (hosts/common/desktop/greeter.nix,
# NixOS), which pass the same nixpkgs as their quickshell so the patched Qt Multimedia matches it.
# The patched Qt Multimedia and VA-API driver are in overlays/default.nix.
{
  # Shell lines for the wrapper that starts quickshell. The quickshell wrapper prepends its
  # own paths to the first two, so these append to whatever is already set.
  environment = ''
    # Qt Multimedia for the clip.
    export NIXPKGS_QT6_QML_IMPORT_PATH=${pkgs.qtmultimedia-vaapi-layers}/${pkgs.qt6.qtbase.qtQmlPrefix}''${NIXPKGS_QT6_QML_IMPORT_PATH:+:$NIXPKGS_QT6_QML_IMPORT_PATH}
    export QT_PLUGIN_PATH=${pkgs.qtmultimedia-vaapi-layers}/${pkgs.qt6.qtbase.qtPluginPrefix}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}
    export QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
    # Nothing here encodes. Unset, Qt probes every hardware device type for encoders at
    # startup (about 1 s, before the first frame); empty skips the probe.
    export QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=
    # Searched first, so only the NVIDIA driver is replaced; others still come from the system.
    export LIBVA_DRIVERS_PATH=${pkgs.nvidia-vaapi-driver-git}/lib/dri:/run/opengl-driver/lib/dri
  '';
}
