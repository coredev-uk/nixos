_: {
  # Custom packages from ../pkgs
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # Patched/rebuilt nixpkgs packages; applied to every nixpkgs the flake uses (lib/helpers.nix).
  # Each needs a "why, and when to drop" comment and a machine-readable removal condition in
  # ./expiry.nix (a check fails without one).
  modifications = final: prev: {
    # nh 4.5.0 passes `systemd-run --output=cat` (needs systemd >= 261); breaks `nh os switch` on
    # 26.05. Backport upstream fix; version guard skips other nh versions. Drop on nh > 4.5.0.
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

    # Plezy on NVIDIA falls to an undescribed fp16 buffer; Hyprland composites it as linear light
    # (blown-out windowed video). Drop the fp16 tier (HDR is off). Drop when Plezy describes it.
    plezy = prev.plezy.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace linux/runner/mpv/wayland_video_surface.cc \
          --replace-fail '{{10, false}, {16, true}, {8, false}}' '{{10, false}, {8, false}}'
      '';
    });

    # Launcher spawns BeamNG natively and needs a full FHS lib set (steam-run's lacks CEF deps).
    # Runs from its own XDG_DATA_HOME dir (writes cfg/logs/mods to cwd), under GameMode + MangoHud
    # (neither automatic); the game inherits their LD_PRELOAD/MANGOHUD. Drop when nixpkgs' launcher
    # runs on NixOS as is.
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
        exec ${steam-run}/bin/steam-run ${final.gamemode}/bin/gamemoderun \
          ${final.mangohud}/bin/mangohud ${prev.beammp-launcher}/bin/BeamMP-Launcher "$@"
      '';

    # Chromecast casting: the TV lags up to ~8 s with x264's 250-frame keyframe interval. Override
    # the "Zero Latency" preset (1 s keyframes, more bitrate) via GST_PRESET_PATH for this app only.
    # Drop when the app's own preset has short keyframes.
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

    # The two below only serve the lock/greeter wallpaper clip (quickshell/video.nix); separate
    # names rather than replacing the system packages.

    # Qt's VA-API path copied every frame via CPU on NVIDIA (composed layers are refused). Enable
    # Qt's separate-layers path and import planes with the driver's formats (RG88/RG1616, not
    # GR88/GR1616). Drop when upstream Qt does this.
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

    # master build: up to 0.0.18 the 16-slot decoded-frame queue could wrap and hang vaSyncSurface
    # (lock screen froze). Fixed in upstream #465. Drop for nixpkgs' once a release has it.
    nvidia-vaapi-driver-git = prev.nvidia-vaapi-driver.overrideAttrs {
      version = "0.0.18-unstable-2026-10-11";
      src = final.fetchFromGitHub {
        owner = "elFarto";
        repo = "nvidia-vaapi-driver";
        rev = "443050726fdb30888a2ced1cea1c5d036ea3b15c";
        hash = "sha256-E2c4Hn4A0Vx3lcmP/Ms7FHEtxsDcxhCmcVFvct1Uv+0=";
      };
    };

    # xdph can't change what a running screen share shows; the patch adds
    # uk.coredev.xdph.ScreenCast.SwitchSource on /org/freedesktop/portal/desktop, which re-runs the
    # picker and points every active share at the choice (the bar's screen-share glyph calls it,
    # quickshell services/Privacy.qml). Drop when xdph can switch a running share's source.
    xdg-desktop-portal-hyprland = prev.xdg-desktop-portal-hyprland.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./xdph-switch-source.patch ];
    });
  };
}
