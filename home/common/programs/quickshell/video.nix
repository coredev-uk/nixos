{ pkgs }:

# What a Quickshell instance needs to play the wallpaper's aerial clip (config/lock/LockVideo.qml):
# shared by the lock (default.nix, home-manager) and the greeter (hosts/common/desktop/greeter.nix,
# NixOS), which pass the same nixpkgs as their quickshell so the patched Qt Multimedia matches it.
rec {
  # Qt decodes with VA-API but copied every frame through the CPU on NVIDIA: it exports frames
  # as composed layers, which nvidia-vaapi-driver refuses, so each export failed and Qt fell
  # back to a copy. Qt has the separate-layers path behind a constant; turn it on and import
  # each plane with the format the driver reports (RG88/RG1616 chroma, where Qt assumes
  # GR88/GR1616 and NVIDIA's EGL rejects those). Both screens playing 1440p120: about 75% of a
  # core before, 45% after; Mesa drivers support separate layers too.
  qtMultimedia = pkgs.qt6.qtmultimedia.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/plugins/multimedia/ffmpeg/qffmpeghwaccel_vaapi.cpp \
        --replace-fail "constexpr bool VAExportUseLayers = false;" \
          "constexpr bool VAExportUseLayers = true;" \
        --replace-fail "planes[i].drmFormat = drm_formats[i];" \
          "planes[i].drmFormat = VAExportUseLayers ? DRMFormat(prime.layers[i].drm_format) : drm_formats[i];" \
        --replace-fail "if (prime.layers[i].drm_format != quint32(drm_formats[i])) {" \
          "if (false) {"
    '';
  });

  # nvidia-vaapi-driver from master, for the clip only. Up to 0.0.18 its 16-slot queue of
  # decoded frames could wrap and drop one under a decode backlog (FFmpeg runs 16 frame threads
  # per player), and vaSyncSurface on that frame then waited forever: with a player per screen
  # the lock froze within a second, nearly every time. Fixed upstream in #465 (grow the queue),
  # after 0.0.18; back to the nixpkgs package once a release has it.
  vaapiDriver = pkgs.nvidia-vaapi-driver.overrideAttrs {
    version = "0.0.18-unstable-2026-10-11";
    src = pkgs.fetchFromGitHub {
      owner = "elFarto";
      repo = "nvidia-vaapi-driver";
      rev = "443050726fdb30888a2ced1cea1c5d036ea3b15c";
      hash = "sha256-E2c4Hn4A0Vx3lcmP/Ms7FHEtxsDcxhCmcVFvct1Uv+0=";
    };
  };

  # Shell lines for the wrapper that starts quickshell. The quickshell wrapper prepends its
  # own paths to the first two, so these append to whatever is already set.
  environment = ''
    # Qt Multimedia for the clip.
    export NIXPKGS_QT6_QML_IMPORT_PATH=${qtMultimedia}/${pkgs.qt6.qtbase.qtQmlPrefix}''${NIXPKGS_QT6_QML_IMPORT_PATH:+:$NIXPKGS_QT6_QML_IMPORT_PATH}
    export QT_PLUGIN_PATH=${qtMultimedia}/${pkgs.qt6.qtbase.qtPluginPrefix}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}
    export QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
    # Nothing here encodes. Unset, Qt probes every hardware device type for encoders at
    # startup (about 1 s, before the first frame); empty skips the probe.
    export QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=
    # Searched first, so only the NVIDIA driver is replaced; others still come from the system.
    export LIBVA_DRIVERS_PATH=${vaapiDriver}/lib/dri:/run/opengl-driver/lib/dri
  '';
}
