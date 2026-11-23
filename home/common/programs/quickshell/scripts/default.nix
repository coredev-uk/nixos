# Helper programs for the shell: each wraps a script here (or a QML entry point in ../config).
{
  config,
  lib,
  pkgs,
}:
let
  # ProtonVPN has no D-Bus API; the bar uses its CLI.
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

  # headsetcontrol is not a runtime input: it comes from the host PATH (hosts/atlas/extra.nix) with its udev rules.
  batteries = pkgs.writeShellApplication {
    name = "quickshell-batteries";
    runtimeInputs = with pkgs; [
      jq
      systemd # busctl, for the OpenRazer daemon
    ];
    text = builtins.readFile ./batteries.sh;
  };

  # OpenRGB SDK client against the system server (hosts/common/desktop/rgb.nix): looks plus the
  # engine behind quickshell-rgb.service.
  rgb = pkgs.writers.writePython3Bin "quickshell-rgb" {
    libraries = [ pkgs.python3Packages.openrgb-python ];
  } (builtins.readFile ./rgb.py);

  # Nix view data (services/NixStatus.qml): GitHub (flake.lock, update PR, Hosts workflow; `gh auth
  # token` from the user's PATH if present), Attic narinfo and Prometheus cache size, fetched in
  # parallel with short timeouts into one JSON object. nixos-version and systemctl are called by
  # absolute path from the running system.
  nixStatus = pkgs.writeShellApplication {
    name = "quickshell-nix-status";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
    ];
    text = builtins.readFile ./nix-status.sh;
  };

  # Claude plan usage from the endpoint behind claude.ai's settings, using omp's Anthropic
  # credential (read only, never refreshed); also keeps the week's readings for the chart.
  claudeUsage = pkgs.writeShellApplication {
    name = "quickshell-claude-usage";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
      sqlite
    ];
    # jq filters are single-quoted on purpose.
    excludeShellChecks = [ "SC2016" ];
    text = builtins.readFile ./claude-usage.sh;
  };

  # pass-cli is not a runtime input: it comes from the user's PATH (home/common/desktop/default.nix)
  # to share the signed-in session. dwebp converts WebP site icons to PNG for Qt; the public suffix
  # list groups websites by site. Hidden vaults are excluded from the list and from sync.
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
      # One per line: names may contain spaces.
      QUICKSHELL_PASS_HIDDEN_VAULTS = lib.concatStringsSep "\n" [
        "Alias"
        "Kubernetes"
        "CI"
      ];
    };
    text = builtins.readFile ./pass.sh;
  };

  # gpu-screen-recorder comes from the NixOS module (hosts/common/desktop/hyprland.nix), whose
  # build finds the capability wrapper needed for KMS capture.
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

  # iCloud CalDAV and Sonarr/Radarr events from ~/.config/quickshell/calendars.json (not in git;
  # format in the script header). pass-cli comes from PATH, as for quickshell-pass.
  calendar = pkgs.writers.writePython3Bin "quickshell-calendar" {
    libraries = with pkgs.python3Packages; [
      caldav
      requests
    ];
  } (builtins.readFile ./calendar-events.py);

  # Print key and screenshot popup. Saves to the XDG screenshots dir (home/common/shell/xdg.nix).
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

  # Qt Multimedia + NVIDIA VA-API for the lock clip; the greeter uses it too.
  video = import ../video.nix { inherit pkgs; };

  # Own one-shot instance (hypridle lock_cmd, hypr/idle.nix) so bar restarts can't drop the lock.
  # The idle timeout runs `quickshell-lock --grace SECONDS`: input within SECONDS dismisses the
  # lock without the password.
  lock = pkgs.writeShellApplication {
    name = "quickshell-lock";
    runtimeInputs = [
      config.programs.quickshell.package
      pkgs.coreutils
      pkgs.libnotify
      pkgs.systemd
      # Today's events under the clock.
      calendar
    ];
    text = ''
      # `--grace SECONDS`: leave a note, then lock via logind (lock_cmd re-runs this without args)
      # so other lock listeners still fire. Sleep/manual locks never write one.
      grace_note="$XDG_RUNTIME_DIR/quickshell-lock-grace"
      if [ "''${1:-}" = --grace ]; then
        printf '%s\n' "''${2:?--grace needs a number of seconds}" > "$grace_note"
        exec loginctl lock-session
      fi

      # Honour the note only if fresh; a stale one must not soften a later lock.
      grace=0
      if [ -f "$grace_note" ]; then
        if [ $(( $(date +%s) - $(stat -c %Y "$grace_note") )) -le 5 ]; then
          grace=$(cat "$grace_note")
        fi
        rm -f "$grace_note"
      fi
      export QS_LOCK_GRACE="$grace"

      # The PAM service comes from the NixOS config (hosts/common/desktop/hyprland.nix); without it
      # the lock can't be dismissed, so refuse to lock.
      if [ ! -e /etc/pam.d/quickshell-lock ]; then
        notify-send --urgency=critical "Screen not locked" \
          "/etc/pam.d/quickshell-lock is missing; rebuild NixOS first."
        exit 1
      fi

      # Wallpaper (hypr/paper.nix).
      export QS_LOCK_WALLPAPER=${lib.escapeShellArg "${config.xdg.cacheHome}/wallpapers/current.jpg"}
      # wlsunset's location, for the next sunrise/sunset.
      export QS_LATITUDE=${lib.escapeShellArg config.services.wlsunset.latitude}
      export QS_LONGITUDE=${lib.escapeShellArg config.services.wlsunset.longitude}
      # Aerial clip from wallpaper-video (hypr/paper.nix); the still shows until it exists.
      export QS_LOCK_VIDEO=${lib.escapeShellArg "${config.xdg.cacheHome}/wallpapers/current.mp4"}
      ${video.environment}
      exec quickshell --no-duplicate --path ${../config}/lockscreen.qml
    '';
  };

  # xdph's screen-share picker (screencopy:custom_picker_binary): prints "[SELECTION]<flags>/<what>"
  # on stdout; no line = cancel. Own instance so bar restarts can't close it.
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
