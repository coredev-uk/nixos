_: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # Every patched or rebuilt nixpkgs package, in one place. Each says why, and when it can go.
  # The overlay is applied to every nixpkgs the flake uses (the system's, Home Manager's and the
  # `unstable` special argument, lib/helpers.nix), so an override here is the one everyone gets.
  modifications = final: prev: {
    # nh 4.5.0 (home-manager's, from unstable) passes `systemd-run --output=cat`,
    # which only systemd >= 261 accepts, so `nh os switch` fails activation on
    # NixOS 26.05. Backport the upstream fix (version check + `--pipe` fallback);
    # the version guard leaves 26.05's nh 4.4.2 and any later release untouched.
    nh = prev.nh.overrideAttrs (old: {
      patches =
        (old.patches or [ ])
        ++ final.lib.optional (old.version == "4.5.0") (
          final.fetchpatch {
            name = "nh-systemd-run-pipe-fallback.patch";
            url = "https://github.com/nix-community/nh/commit/a5adbe165150f7f26778616ec918d3a0f8437a0a.patch";
            excludes = [ "CHANGELOG.md" ];
            hash = "sha256-bGHkV+fS5U54tK6hkaflAnJKFcfZ3YHEWmO2h18Q37Y=";
          }
        );
    });

    # Plezy draws video into its own Wayland subsurface. On NVIDIA (no 10-bit EGL window configs
    # through 610.xx) it falls to a half-float (fp16) buffer, which it leaves undescribed while HDR
    # is off; Hyprland composites an undescribed fp16 buffer as linear light, so windowed video
    # came out blown out while fullscreen (scanned out raw) looked right. HDR is off here (SDR
    # desktop), so drop the fp16 tier: the plane gets an 8-bit sRGB buffer and Hyprland shows it
    # as is, windowed or fullscreen. Drop when Plezy describes its fp16 buffer.
    plezy = prev.plezy.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace linux/runner/mpv/wayland_video_surface.cc \
          --replace-fail '{{10, false}, {16, true}, {8, false}}' '{{10, false}, {8, false}}'
      '';
    });

    # BeamMP's launcher spawns the native BinLinux/BeamNG.drive.x64 itself, which needs a full FHS
    # library set; steam-run's lacks what the game's CEF UI (libcef.so) links against, hence the
    # extra libraries. It writes Launcher.cfg, Launcher.log and its mod cache (./Resources) to the
    # directory it runs from, so it always runs from its own in XDG_DATA_HOME.
    beammp-launcher =
      let
        steam-run =
          (final.steam.override {
            extraPkgs = p: [
              p.at-spi2-core
              p.libxcomposite
              p.nspr
              p.nss
            ];
          }).run;
      in
      final.writeShellScriptBin "BeamMP-Launcher" ''
        dir="''${XDG_DATA_HOME:-$HOME/.local/share}/BeamMP-Launcher"
        mkdir -p "$dir"
        cd "$dir"
        exec ${steam-run}/bin/steam-run ${prev.beammp-launcher}/bin/BeamMP-Launcher "$@"
      '';

    # Screen casting to Chromecast (the shell's Cast screen row). The TV fetches the stream over
    # HTTP, and whenever it (re)connects GNOME Network Displays replays it from the latest
    # keyframe; with x264's default interval of 250 frames that left the TV up to ~8 s behind the
    # screen. Its encoder loads x264enc's "Zero Latency" preset, so a copy of the preset file with
    # a 1 s keyframe interval (and more bitrate to pay for the extra keyframes) takes over through
    # GST_PRESET_PATH, for this app only.
    gnome-network-displays =
      let
        presets = final.runCommand "gnome-network-displays-presets" { } ''
          mkdir $out
          substitute ${final.gst_all_1.gst-plugins-ugly}/share/gstreamer-1.0/presets/GstX264Enc.prs \
            $out/GstX264Enc.prs \
            --replace-fail $'[Zero Latency]\ntune=zerolatency' $'[Zero Latency]\ntune=zerolatency\nkey-int-max=30\nbitrate=6000'
        '';
      in
      final.symlinkJoin {
        name = "gnome-network-displays";
        paths = [ prev.gnome-network-displays ];
        nativeBuildInputs = [ final.makeWrapper ];
        postBuild = ''
          for bin in $out/bin/*; do
            wrapProgram "$bin" --set GST_PRESET_PATH ${presets}
          done
        '';
      };

    # The two below are only for the wallpaper clip behind the lock screen and the greeter
    # (home/common/programs/quickshell/video.nix), so they get names of their own rather than
    # replacing the system-wide packages.

    # Qt decodes with VA-API but copied every frame through the CPU on NVIDIA: it exports frames
    # as composed layers, which nvidia-vaapi-driver refuses, so each export failed and Qt fell
    # back to a copy. Qt has the separate-layers path behind a constant; turn it on and import
    # each plane with the format the driver reports (RG88/RG1616 chroma, where Qt assumes
    # GR88/GR1616 and NVIDIA's EGL rejects those). Both screens playing 1440p120: about 75% of a
    # core before, 45% after; Mesa drivers support separate layers too.
    qtmultimedia-vaapi-layers = prev.qt6.qtmultimedia.overrideAttrs (old: {
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

    # nvidia-vaapi-driver from master. Up to 0.0.18 its 16-slot queue of decoded frames could
    # wrap and drop one under a decode backlog (FFmpeg runs 16 frame threads per player), and
    # vaSyncSurface on that frame then waited forever: with a player per screen the lock froze
    # within a second, nearly every time. Fixed upstream in #465 (grow the queue), after 0.0.18;
    # drop for nixpkgs' nvidia-vaapi-driver once a release has it.
    nvidia-vaapi-driver-git = prev.nvidia-vaapi-driver.overrideAttrs {
      version = "0.0.18-unstable-2026-10-11";
      src = final.fetchFromGitHub {
        owner = "elFarto";
        repo = "nvidia-vaapi-driver";
        rev = "443050726fdb30888a2ced1cea1c5d036ea3b15c";
        hash = "sha256-E2c4Hn4A0Vx3lcmP/Ms7FHEtxsDcxhCmcVFvct1Uv+0=";
      };
    };
  };
}
