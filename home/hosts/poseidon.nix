{ pkgs, ... }:
{

  imports = [
    ../common/programs/discord.nix
    ../common/programs/ghostty.nix
    ../common/programs/zen
  ];

  home.packages = with pkgs; [
    # System Packages
    mediamate
    raycast
    # bartender # Need v6

    # Utilities
    alt-tab-macos
    mas

    # Apps
    protonmail-desktop
  ];

  programs.ghostty.package = pkgs.ghostty-bin;
}
