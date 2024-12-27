{ pkgs, self, ... }:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  imports = [
    # ./atuin.nix
    ./bat.nix
    ./bottom.nix
    # ./fzf.nix
    ./ghostty.nix
    ./git.nix
    ./fastfetch.nix
    ./starship.nix
    # ./tmux.nix
    ./vim.nix
    ./xdg.nix
    ./zsh.nix
  ];

  catppuccin = {
    inherit (theme.catppuccin) flavor;
    inherit (theme.catppuccin) accent;
  };

  programs = {
    eza.enable = true;
    git.enable = true;
    home-manager.enable = true;
    jq.enable = true;
  };

  home.packages = with pkgs; [
    age
    btop
    protonvpn-cli
    sops
  ];
}
