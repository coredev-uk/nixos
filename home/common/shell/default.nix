{
  pkgs,
  self,
  lib,
  meta,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  imports = [
    ./bat.nix
    ./btop.nix
    ./fastfetch.nix
    ./nh.nix
    ./opencode.nix
    ./starship.nix
    ./ssh.nix
    ./zsh.nix
    ../programs/nixvim
  ]
  ++ lib.optional (!meta.isHeadless) ./git.nix
  ++ lib.optionals meta.isDesktop [
    ./xdg.nix
  ];

  catppuccin = {
    inherit (theme.catppuccin) flavor;
    inherit (theme.catppuccin) accent;
  };

  programs = {
    eza.enable = true;
    home-manager.enable = true;
  };

  home.packages = with pkgs; [
    age
    # termscp
    typst
  ];
}
