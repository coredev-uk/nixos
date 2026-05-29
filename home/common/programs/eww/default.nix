{ pkgs, ... }:

let
  ewwMusic = pkgs.writeScriptBin "eww-music" (builtins.readFile ./config/scripts/music.sh);
  ewwPanel = pkgs.writeScriptBin "eww-panel" (builtins.readFile ./config/scripts/panel.sh);
  ewwVpn = pkgs.writeScriptBin "eww-vpn" (builtins.readFile ./config/scripts/vpn.sh);
  ewwNetwork = pkgs.writeScriptBin "eww-network" (builtins.readFile ./config/scripts/network.sh);
  ewwBluetooth = pkgs.writeScriptBin "eww-bluetooth" (
    builtins.readFile ./config/scripts/bluetooth.sh
  );
  ewwWorkspace = pkgs.writeScriptBin "eww-workspace" (
    builtins.readFile ./config/scripts/workspace.sh
  );
in
{
  programs.eww = {
    enable = true;

    yuckConfig = builtins.readFile ./config/eww.yuck;
    scssConfig = builtins.readFile ./config/eww.scss;

    systemd.enable = true;
  };

  # Needed for scripts
  home.packages = with pkgs; [
    bluez
    coreutils
    findutils
    gawk
    gnugrep
    gnused
    iproute2
    jq
    socat
    ffmpeg
    networkmanager
    playerctl

    ewwBluetooth
    ewwMusic
    ewwNetwork
    ewwPanel
    ewwVpn
    ewwWorkspace
  ];
}
