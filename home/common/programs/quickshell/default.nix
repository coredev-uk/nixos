{
  config,
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

  # atlas's Nix state and the home-lab binary cache for the panel's Nix view
  # (config/services/NixStatus.qml): main's flake.lock, the open lock update pull requests
  # (the nightly trials, one per flake input, and the landing one) and their checks, and the Hosts
  # workflow's runs on main (GitHub's API, with `gh auth token` from the user's PATH when it has
  # one), and the cache's narinfo, pin for main and stats, fetched in parallel with short timeouts into one JSON object.
  # nixos-version comes from the running system by absolute path, as does systemctl (failed units,
  # system and user).
  quickshellNixStatus = pkgs.writeShellApplication {
    name = "quickshell-nix-status";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
    ];
    text = builtins.readFile ./scripts/nix-status.sh;
  };

  # Proton Pass quick access (config/modules/PassQuickAccess.qml). pass-cli is not a runtime
  # input: it comes from the user's PATH (home/common/desktop/default.nix), sharing the session
  # the user signs in to. curl fetches the logins' website icons, dwebp (libwebp) turns the WebP
  # ones into PNGs for the shell's Qt, and the public suffix list tells which websites share a site.
  quickshellPass = pkgs.writeShellApplication {
    name = "quickshell-pass";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      findutils
      jq
      libwebp # dwebp
      util-linux # flock
      wl-clipboard
    ];
    runtimeEnv.PUBLIC_SUFFIX_LIST = "${pkgs.publicsuffix-list}/share/publicsuffix/public_suffix_list.dat";
    text = builtins.readFile ./scripts/pass.sh;
  };

  # Screen recording (config/services/Recorder.qml): gpu-screen-recorder itself comes from the
  # NixOS module (hosts/common/desktop/hyprland.nix), whose build finds the capability wrapper
  # for KMS capture; the script starts it and raises the notifications.
  quickshellRecord = pkgs.writeShellApplication {
    name = "quickshell-record";
    runtimeInputs = with pkgs; [
      coreutils
      libnotify
      systemd # systemd-run
      util-linux # setpriv
      xdg-utils
    ];
    text = builtins.readFile ./scripts/record.sh;
  };

  # Instant replay (config/services/Replay.qml, the quickshell-replay unit below). The one place
  # that says how much is kept and of which screen. Kept in RAM at 20 Mbit/s (scripts/record.sh),
  # so every minute costs 150 MB: 300 s is 750 MB. The monitor is the gaming one (the 165 Hz
  # screen with VRR, workspace 1 at login; home/common/desktop/hyprland/config/monitors.nix).
  replaySeconds = 300;
  replayMonitor = "DP-1";

  # Events for the calendar popup (config/services/Calendar.qml): iCloud over CalDAV and the
  # Sonarr/Radarr release calendars, from ~/.config/quickshell/calendars.json (kept out of git;
  # format in the script's header). pass:// secrets come from Proton Pass; pass-cli is not a
  # runtime input, for the same reason as quickshell-pass above.
  quickshellCalendar = pkgs.writers.writePython3Bin "quickshell-calendar" {
    libraries = with pkgs.python3Packages; [
      caldav
      requests
    ];
  } (builtins.readFile ./scripts/calendar-events.py);

  # Print key and the screenshot popup (config/modules/ScreenshotPopup.qml): capture, save and
  # edit. Saves go to the XDG screenshots directory (home/common/shell/xdg.nix).
  quickshellScreenshot = pkgs.writeShellApplication {
    name = "quickshell-screenshot";
    runtimeInputs = with pkgs; [
      config.programs.quickshell.package
      coreutils
      grimblast
      satty
      wl-clipboard
    ];
    text = ''
      export QS_SCREENSHOTS=${lib.escapeShellArg config.xdg.userDirs.extraConfig.SCREENSHOTS}
    ''
    + builtins.readFile ./scripts/screenshot.sh;
  };

  # Qt Multimedia and the NVIDIA VA-API driver for the clip behind the lock screen
  # (config/lock/LockVideo.qml); the greeter plays it too (hosts/common/desktop/greeter.nix).
  video = import ./video.nix { inherit pkgs; };

  # Session lock (config/lockscreen.qml): its own one-shot instance, run by hypridle's lock_cmd
  # (home/common/programs/hypr/idle.nix), so a bar restart can't take the lock down. The idle
  # timeout runs `quickshell-lock --grace SECONDS` instead, for a lock that input in its first
  # SECONDS dismisses without the password.
  quickshellLock = pkgs.writeShellApplication {
    name = "quickshell-lock";
    runtimeInputs = [
      config.programs.quickshell.package
      pkgs.coreutils
      pkgs.libnotify
      pkgs.systemd
      # Today's events under the clock (config/lock/LockToday.qml).
      quickshellCalendar
    ];
    text = ''
      # `--grace SECONDS`: leave a note for the lock logind is about to start (lock_cmd runs this
      # again, without arguments) and go through logind like every other lock, so whatever else
      # listens for it still hears. Locks for sleep or by hand never write one.
      grace_note="$XDG_RUNTIME_DIR/quickshell-lock-grace"
      if [ "''${1:-}" = --grace ]; then
        printf '%s\n' "''${2:?--grace needs a number of seconds}" > "$grace_note"
        exec loginctl lock-session
      fi

      # Read the note once, and only if it was just left: a stale one (lock-session never got
      # here) mustn't soften a later lock.
      grace=0
      if [ -f "$grace_note" ]; then
        if [ $(( $(date +%s) - $(stat -c %Y "$grace_note") )) -le 5 ]; then
          grace=$(cat "$grace_note")
        fi
        rm -f "$grace_note"
      fi
      export QS_LOCK_GRACE="$grace"

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
      ${video.environment}
      exec quickshell --no-duplicate --path ${./config}/lockscreen.qml
    '';
  };

  # Screen casting to Chromecast, from the Connections panel's Cast screen row. The TV fetches
  # the stream over HTTP, and whenever it (re)connects GNOME Network Displays replays it from the
  # latest keyframe; with x264's default interval of 250 frames that left the TV up to ~8 s behind the
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

  # xdph's screen-share picker (screencopy:custom_picker_binary): runs config/sharepicker.qml
  # and hands its choice back on stdout, which xdph parses as "[SELECTION]<flags>/<what>"; no
  # line is a cancel. Its own instance, like the lock, so a bar restart can't close it.
  quickshellSharePicker = pkgs.writeShellApplication {
    name = "quickshell-share-picker";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      out=$(mktemp -t quickshell-share-picker.XXXXXX)
      trap 'rm -f "$out"' EXIT
      allow=0
      for arg in "$@"; do
        if [ "$arg" = --allow-token ]; then
          allow=1
        fi
      done
      # Quickshell's log would land in the stdout xdph reads.
      QS_SHARE_OUT="$out" QS_SHARE_ALLOW_TOKEN="$allow" \
        ${lib.getExe config.programs.quickshell.package} --path ${./config}/sharepicker.qml >/dev/null 2>&1 || true
      if [ -s "$out" ]; then
        printf '[SELECTION]%s\n' "$(cat "$out")"
      fi
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

  # The instant replay buffer (config/services/Replay.qml). A unit of its own, not a child of the
  # bar, so the bar's restarts on switch don't empty the buffer, and systemd restarts it if the
  # recorder dies (a driver reset, a resume from suspend). Not wanted by anything: the bar starts
  # it when replay is armed (state kept in its state dir) and the toggle stops it. SIGINT ends
  # the recorder cleanly; after five failures in five minutes the unit stays failed and the bar
  # turns replay off and says why.
  systemd.user.services.quickshell-replay = {
    Unit = {
      Description = "Instant replay buffer (Quickshell)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      StartLimitIntervalSec = 300;
      StartLimitBurst = 5;
    };
    Service = {
      ExecStart = "${lib.getExe quickshellRecord} --replay ${replayMonitor} ${config.xdg.userDirs.extraConfig.RECORDINGS} ${toString replaySeconds}";
      KillSignal = "SIGINT";
      Restart = "on-failure";
      RestartSec = 5;
    };
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
    # Where screen recordings go (xdg.userDirs, home/common/shell/xdg.nix).
    "QS_RECORDINGS_DIR=${config.xdg.userDirs.extraConfig.RECORDINGS}"
    # Instant replay (replaySeconds, replayMonitor above), for the capture menu's labels.
    "QS_REPLAY_SECONDS=${toString replaySeconds}"
    "QS_REPLAY_MONITOR=${replayMonitor}"
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
    quickshellNixStatus
    quickshellLock
    quickshellPass
    quickshellCalendar
    quickshellScreenshot
    quickshellRecord
  ];

  # Read when xdph starts: restart xdg-desktop-portal-hyprland after a change.
  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      custom_picker_binary = ${quickshellSharePicker}/bin/quickshell-share-picker
    }
  '';
}
