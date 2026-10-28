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

  # Session lock (config/lockscreen.qml): its own one-shot instance, run by hypridle's lock_cmd
  # (home/common/programs/hypr/idle.nix), so a bar restart can't take the lock down.
  quickshellLock = pkgs.writeShellApplication {
    name = "quickshell-lock";
    runtimeInputs = [
      config.programs.quickshell.package
      pkgs.libnotify
    ];
    text = ''
      # Without its PAM service the lock could never be dismissed; it comes from the NixOS
      # config (hosts/common/desktop/hyprland.nix), so refuse to lock on a system without it.
      if [ ! -e /etc/pam.d/quickshell-lock ]; then
        notify-send --urgency=critical "Screen not locked" \
          "/etc/pam.d/quickshell-lock is missing; rebuild NixOS first."
        exit 1
      fi

      # The wallpaper hyprpaper shows (home/common/programs/hypr/paper.nix).
      export QS_LOCK_WALLPAPER=${lib.escapeShellArg "${config.xdg.cacheHome}/wallpapers/current.jpg"}
      if [ -e "$HOME/.face" ]; then
        export QS_LOCK_AVATAR="$HOME/.face"
      fi
      exec quickshell --no-duplicate --path ${./config}/lockscreen.qml
    '';
  };
in
{
  programs.quickshell = {
    enable = true;
    configs.bar = ./config;
    activeConfig = "bar";
    systemd.enable = true;
  };

  # The config is a store symlink and fonts are only read at startup, so a running
  # instance never sees either change; restart it on switch instead.
  systemd.user.services.quickshell.Unit.X-Restart-Triggers = [
    "${./config}"
    "${theme.fonts.iconFont.package}"
  ];

  # Electron tray items (Discord, 1Password) expose IconPixmap but no IconName, so every
  # icon update logs a harmless "Error updating property …IconName" warning (~1k per boot).
  systemd.user.services.quickshell.Service.Environment = [
    "QT_LOGGING_RULES=quickshell.dbus.properties.warning=false"
  ];

  home.packages = [
    # The bar's glyphs; installed here so it doesn't depend on the system font set.
    theme.fonts.iconFont.package
    pkgs.iproute2
    # Holds the night light's session temperature (config/services/NightLight.qml).
    pkgs.hyprsunset
    # Screen casting to Chromecast/Miracast, opened from the panel's Cast view.
    pkgs.gnome-network-displays
    quickshellVpn
    quickshellBatteries
    quickshellLock
    quickshellPass
    quickshellCalendar
  ];
}
