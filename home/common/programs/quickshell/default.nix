{ pkgs, self, ... }:

let
  theme = import "${self}/lib/theme" { inherit pkgs; };

  # ProtonVPN has no D-Bus API, so the bar shells out to its CLI.
  quickshellVpn = pkgs.writeShellApplication {
    name = "quickshell-vpn";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      iproute2
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

  home.packages = [
    # The bar's glyphs; installed here so it doesn't depend on the system font set.
    theme.fonts.iconFont.package
    pkgs.iproute2
    quickshellVpn
  ];
}
