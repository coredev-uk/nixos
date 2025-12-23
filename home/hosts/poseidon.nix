{ pkgs, ... }:
{

  imports = [
    # ../common/programs/discord.nix
    ../common/programs/ghostty.nix # NixOS/nixpkgs#388984
    ../common/programs/zen.nix
  ];

  home.packages = with pkgs; [
    discord # TODO: fix issue with nixcord

    # System Packages
    mediamate
    raycast
    bartender

    # Utilities
    alt-tab-macos
    mas
  ];

  programs.ghostty.package = pkgs.ghostty-bin;
}
