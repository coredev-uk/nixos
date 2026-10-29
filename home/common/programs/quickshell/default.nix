{
  config,
  inputs,
  lib,
  pkgs,
  self,
  ...
}:

let
  theme = import "${self}/lib/theme" { inherit pkgs; };

  # ProtonVPN has no D-Bus API, so the bar shells out to its CLI.
  quickshellVpn = pkgs.writeShellApplication {
    name = "quickshell-vpn";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gawk
      gnugrep
      gnused
      iproute2
      jq
      libnotify
      networkmanager
    ];
    text = builtins.readFile ./scripts/vpn.sh;
  };

  # Peripheral batteries for the panel (services/Batteries.qml). headsetcontrol is not a
  # runtime input: it comes from the host's PATH where installed (hosts/atlas/extra.nix),
  # together with its udev rules.
  quickshellBatteries = pkgs.writeShellApplication {
    name = "quickshell-batteries";
    runtimeInputs = with pkgs; [
      jq
      systemd # busctl, for the OpenRazer daemon
    ];
    text = builtins.readFile ./scripts/batteries.sh;
  };

  # Proton Pass quick access (config/modules/PassQuickAccess.qml). pass-cli is not a runtime
  # input: it comes from the user's PATH (home/common/desktop/default.nix), sharing the session
  # the user signs in to.
  quickshellPass = pkgs.writeShellApplication {
    name = "quickshell-pass";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      util-linux # flock
      wl-clipboard
    ];
    text = builtins.readFile ./scripts/pass.sh;
  };

  # Events for the calendar popup (config/services/Calendar.qml): iCloud over CalDAV and the
  # Sonarr/Radarr release calendars, from ~/.config/quickshell/calendars.json (kept out of git;
  # format in the script's header). pass:// secrets come from Proton Pass; pass-cli is not a
  # runtime input, for the same reason as quickshell-pass above. Built from the stable nixpkgs:
  # unstable's caldav 3 pulls in niquests and urllib3-future, which aren't in the binary cache
  # and whose test suites hang in the offline build sandbox.
  quickshellCalendar =
    let
      stable = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    stable.writers.writePython3Bin "quickshell-calendar" {
      libraries = with stable.python3Packages; [
        caldav
        requests
      ];
    } (builtins.readFile ./scripts/calendar-events.py);

  # Video behind the lock screen (config/lock/LockVideo.qml), only in the lock's own instance.
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

  # nvidia-vaapi-driver from master, for the lock's clip only. Up to 0.0.18 its 16-slot queue of
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

  # Session lock (config/lockscreen.qml): its own one-shot instance, run by hypridle's lock_cmd
  # (home/common/programs/hypr/idle.nix), so a bar restart can't take the lock down.
  quickshellLock = pkgs.writeShellApplication {
    name = "quickshell-lock";
    runtimeInputs = [
      config.programs.quickshell.package
      pkgs.libnotify
      # Today's events under the clock (config/lock/LockToday.qml).
      quickshellCalendar
    ];
    text = ''
      # Without its PAM service the lock could never be dismissed; it comes from the NixOS
      # config (hosts/common/desktop/hyprland.nix), so refuse to lock on a system without it.
      if [ ! -e /etc/pam.d/quickshell-lock ]; then
        notify-send --urgency=critical "Screen not locked" \
          "/etc/pam.d/quickshell-lock is missing; rebuild NixOS first."
        exit 1
      fi

      # The desktop's wallpaper (home/common/programs/hypr/paper.nix).
      export QS_LOCK_WALLPAPER=${lib.escapeShellArg "${config.xdg.cacheHome}/wallpapers/current.jpg"}
      # wlsunset's location (home/common/programs/hypr/sunset.nix), for the next sunrise or sunset.
      export QS_LATITUDE=${lib.escapeShellArg config.services.wlsunset.latitude}
      export QS_LONGITUDE=${lib.escapeShellArg config.services.wlsunset.longitude}
      # The aerial clip of the wallpaper, made by wallpaper-video (home/common/programs/hypr/paper.nix);
      # the still shows until it exists.
      export QS_LOCK_VIDEO=${lib.escapeShellArg "${config.xdg.cacheHome}/wallpapers/current.mp4"}
      # Qt Multimedia for the clip; the quickshell wrapper prepends its own paths to these.
      export NIXPKGS_QT6_QML_IMPORT_PATH=${qtMultimedia}/${pkgs.qt6.qtbase.qtQmlPrefix}''${NIXPKGS_QT6_QML_IMPORT_PATH:+:$NIXPKGS_QT6_QML_IMPORT_PATH}
      export QT_PLUGIN_PATH=${qtMultimedia}/${pkgs.qt6.qtbase.qtPluginPrefix}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}
      export QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
      # Nothing here encodes. Unset, Qt probes every hardware device type for encoders at
      # startup (about 1 s, before the lock's first frame); empty skips the probe.
      export QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=
      # Searched first, so only the NVIDIA driver is replaced; others still come from the system.
      export LIBVA_DRIVERS_PATH=${vaapiDriver}/lib/dri:/run/opengl-driver/lib/dri
      exec quickshell --no-duplicate --path ${./config}/lockscreen.qml
    '';
  };

  # Screen casting to Chromecast, opened from the panel's Cast view. The TV fetches the stream
  # over HTTP, and whenever it (re)connects GNOME Network Displays replays it from the latest
  # keyframe; with x264's default interval of 250 frames that left the TV up to ~8 s behind the
  # screen. Its encoder loads x264enc's "Zero Latency" preset, so a copy of the preset file with
  # a 1 s keyframe interval (and more bitrate to pay for the extra keyframes) takes over through
  # GST_PRESET_PATH, for this app only.
  x264Presets = pkgs.runCommand "gnome-network-displays-presets" { } ''
    mkdir $out
    substitute ${pkgs.gst_all_1.gst-plugins-ugly}/share/gstreamer-1.0/presets/GstX264Enc.prs \
      $out/GstX264Enc.prs \
      --replace-fail $'[Zero Latency]\ntune=zerolatency' $'[Zero Latency]\ntune=zerolatency\nkey-int-max=30\nbitrate=6000'
  '';
  gnomeNetworkDisplays = pkgs.symlinkJoin {
    name = "gnome-network-displays";
    paths = [ pkgs.gnome-network-displays ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" --set GST_PRESET_PATH ${x264Presets}
      done
    '';
  };
in
{
  programs.quickshell = {
    enable = true;
    configs = {
      bar = ./config;
      # Run by quickshell-wallpaper below, not by the module's service.
      wallpaper = ./wallpaper;
    };
    activeConfig = "bar";
    systemd.enable = true;
  };

  # The desktop wallpaper (wallpaper/shell.qml), in place of hyprpaper: its own instance so the
  # bar's restarts on switch never blank the desktop, restarted only when its own file changes.
  # set-wallpaper (home/common/programs/hypr/paper.nix) tells it about a new image over IPC.
  systemd.user.services.quickshell-wallpaper = {
    Unit = {
      Description = "Desktop wallpaper (Quickshell)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${./wallpaper}" ];
    };
    Service = {
      ExecStart = "${lib.getExe config.programs.quickshell.package} --config wallpaper";
      Environment = [
        "QS_WALLPAPER=${config.xdg.cacheHome}/wallpapers/current.jpg"
      ];
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # The config is a store symlink and fonts are only read at startup, so a running
  # instance never sees either change; restart it on switch instead.
  systemd.user.services.quickshell.Unit.X-Restart-Triggers = [
    "${./config}"
    "${theme.fonts.shell.package}"
    "${theme.fonts.iconFont.package}"
  ];

  systemd.user.services.quickshell.Service.Environment = [
    # Electron tray items (Discord, 1Password) expose IconPixmap but no IconName, so every
    # icon update logs a harmless "Error updating property …IconName" warning (~1k per boot).
    "QT_LOGGING_RULES=quickshell.dbus.properties.warning=false"
    # wlsunset's location (home/common/programs/hypr/sunset.nix), for the bar's day arc.
    "QS_LATITUDE=${config.services.wlsunset.latitude}"
    "QS_LONGITUDE=${config.services.wlsunset.longitude}"
  ];

  home.packages = [
    # The shell's face and glyphs; installed here so they don't depend on the system font set.
    theme.fonts.shell.package
    theme.fonts.iconFont.package
    pkgs.iproute2
    # Holds the night light's session temperature (config/services/NightLight.qml).
    pkgs.hyprsunset
    gnomeNetworkDisplays
    quickshellVpn
    quickshellBatteries
    quickshellLock
    quickshellPass
    quickshellCalendar
  ];
}
