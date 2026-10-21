{ pkgs, ... }:

let
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
    pkgs.iproute2
    quickshellVpn
  ];
}
