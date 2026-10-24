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
    quickshellVpn
    quickshellBatteries
    quickshellLock
  ];
}
