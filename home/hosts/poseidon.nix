{ pkgs, ... }:
{

  imports = [
    # ../common/programs/discord.nix
    ../common/programs/ghostty.nix # NixOS/nixpkgs#388984
    ../common/programs/zen.nix
  ];

  home.packages = with pkgs; [
    discord
    mediamate
    raycast
    alt-tab-macos
    bartender
  ];

  programs.ghostty.package = pkgs.ghostty-bin;
}
