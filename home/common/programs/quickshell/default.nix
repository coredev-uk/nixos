{ pkgs, self, ... }:

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
  ];
}
