# The shell's helper programs (../default.nix): each wraps a script beside this file, or a QML
# entry point in ../config, with what it needs at runtime.
{
  config,
  lib,
  pkgs,
}:
let
  # ProtonVPN has no D-Bus API, so the bar shells out to its CLI.
  vpn = pkgs.writeShellApplication {
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
    text = builtins.readFile ./vpn.sh;
  };

  # Peripheral batteries for the panel (services/Batteries.qml). headsetcontrol is not a
  # runtime input: it comes from the host's PATH where installed (hosts/atlas/extra.nix),
  # together with its udev rules.
  batteries = pkgs.writeShellApplication {
    name = "quickshell-batteries";
    runtimeInputs = with pkgs; [
      jq
      systemd # busctl, for the OpenRazer daemon
    ];
    text = builtins.readFile ./batteries.sh;
  };

  # OpenRGB lighting for the control panel's Lighting section (config/services/Lighting.qml),
  # over the SDK of the system's OpenRGB server (hosts/common/desktop/rgb.nix): the looks, and
  # the engine (quickshell-rgb.service, ../default.nix) that draws them in Direct mode.
  rgb = pkgs.writers.writePython3Bin "quickshell-rgb" {
    libraries = [ pkgs.python3Packages.openrgb-python ];
  } (builtins.readFile ./rgb.py);

  # atlas's Nix state and the home-lab binary cache for the panel's Nix view
  # (config/services/NixStatus.qml): main's flake.lock, the open lock update pull request (every
  # flake input at once, nightly) and its checks, and the Hosts workflow's runs on main and the
  # store path its newest successful one recorded (GitHub's API, with `gh auth token` from the
  # user's PATH when it has one), the running system's narinfo in Attic and the cache's size from
  # Prometheus, fetched in parallel with short timeouts into one JSON object.
  # nixos-version comes from the running system by absolute path, as does systemctl (failed units,
  # system and user).
  nixStatus = pkgs.writeShellApplication {
    name = "quickshell-nix-status";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
    ];
    text = builtins.readFile ./nix-status.sh;
  };

  # Claude plan usage for the bar's Claude meter (config/services/ClaudeUsage.qml), from the
  # usage endpoint behind claude.ai's settings, signed in with omp's Anthropic credential (read
  # only, never refreshed), and the week's readings for its chart (claude-usage.sh).
  claudeUsage = pkgs.writeShellApplication {
    name = "quickshell-claude-usage";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
      sqlite
    ];
    # The jq filters are single-quoted on purpose.
    excludeShellChecks = [ "SC2016" ];
    text = builtins.readFile ./claude-usage.sh;
  };

  # Proton Pass quick access (config/modules/PassQuickAccess.qml). pass-cli is not a runtime
  # input: it comes from the user's PATH (home/common/desktop/default.nix), sharing the session
  # the user signs in to. curl fetches the logins' website icons, dwebp (libwebp) turns the WebP
  # ones into PNGs for the shell's Qt, and the public suffix list tells which websites share a site.
  # The hidden vaults stay out of the list (and out of each sync's pass-cli runs).
  pass = pkgs.writeShellApplication {
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
    runtimeEnv = {
      PUBLIC_SUFFIX_LIST = "${pkgs.publicsuffix-list}/share/publicsuffix/public_suffix_list.dat";
      # One per line: the names may have spaces, and quotes would need escaping in the wrapper.
      QUICKSHELL_PASS_HIDDEN_VAULTS = lib.concatStringsSep "\n" [
        "Alias"
        "Kubernetes"
        "CI"
      ];
    };
    text = builtins.readFile ./pass.sh;
  };

  # Screen recording (config/services/Recorder.qml): gpu-screen-recorder itself comes from the
  # NixOS module (hosts/common/desktop/hyprland.nix), whose build finds the capability wrapper
  # for KMS capture; the script starts it and raises the notifications.
  record = pkgs.writeShellApplication {
    name = "quickshell-record";
    runtimeInputs = with pkgs; [
      coreutils
      libnotify
      systemd # systemd-run
      util-linux # setpriv
      xdg-utils
    ];
    text = builtins.readFile ./record.sh;
  };

  # Events for the calendar popup (config/services/Calendar.qml): iCloud over CalDAV and the
  # Sonarr/Radarr release calendars, from ~/.config/quickshell/calendars.json (kept out of git;
  # format in the script's header). pass:// secrets come from Proton Pass; pass-cli is not a
  # runtime input, for the same reason as quickshell-pass above.
  calendar = pkgs.writers.writePython3Bin "quickshell-calendar" {
    libraries = with pkgs.python3Packages; [
      caldav
      requests
    ];
  } (builtins.readFile ./calendar-events.py);

  # Print key and the screenshot popup (config/modules/ScreenshotPopup.qml): capture, save and
  # edit. Saves go to the XDG screenshots directory (home/common/shell/xdg.nix).
  screenshot = pkgs.writeShellApplication {
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
    + builtins.readFile ./screenshot.sh;
  };

  # Qt Multimedia and the NVIDIA VA-API driver for the clip behind the lock screen
  # (config/lock/LockVideo.qml); the greeter plays it too (hosts/common/desktop/greeter.nix).
  video = import ../video.nix { inherit pkgs; };

  # Session lock (config/lockscreen.qml): its own one-shot instance, run by hypridle's lock_cmd
  # (home/common/programs/hypr/idle.nix), so a bar restart can't take the lock down. The idle
  # timeout runs `quickshell-lock --grace SECONDS` instead, for a lock that input in its first
  # SECONDS dismisses without the password.
  lock = pkgs.writeShellApplication {
    name = "quickshell-lock";
    runtimeInputs = [
      config.programs.quickshell.package
      pkgs.coreutils
      pkgs.libnotify
      pkgs.systemd
      # Today's events under the clock (config/lock/LockToday.qml).
      calendar
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
      exec quickshell --no-duplicate --path ${../config}/lockscreen.qml
    '';
  };

  # xdph's screen-share picker (screencopy:custom_picker_binary): runs config/sharepicker.qml
  # and hands its choice back on stdout, which xdph parses as "[SELECTION]<flags>/<what>"; no
  # line is a cancel. Its own instance, like the lock, so a bar restart can't close it.
  sharePicker = pkgs.writeShellApplication {
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
        ${lib.getExe config.programs.quickshell.package} --path ${../config}/sharepicker.qml >/dev/null 2>&1 || true
      if [ -s "$out" ]; then
        printf '[SELECTION]%s\n' "$(cat "$out")"
      fi
    '';
  };
in
{
  inherit
    vpn
    batteries
    rgb
    nixStatus
    claudeUsage
    pass
    record
    calendar
    screenshot
    lock
    sharePicker
    ;
}
