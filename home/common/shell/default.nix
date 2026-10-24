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
    ./atuin.nix
    ./bat.nix
    ./btop.nix
    ./omp.nix
    ./fastfetch.nix
    ./nh.nix
    ./nix-index.nix
    ./ssh.nix
    ./zellij.nix
    ./zsh.nix
    ../programs/nixvim
  ]
  ++ lib.optional (!meta.isHeadless) ./git.nix
  ++ lib.optionals meta.isDesktop [
    ./xdg.nix
  ];

  catppuccin = {
    enable = true;
    autoEnable = true;
    inherit (theme.catppuccin) flavor;
    inherit (theme.catppuccin) accent;
  };

  programs = {
    eza = {
      enable = true;
      git = true;
      extraOptions = [
        "--group"
        "--group-directories-first"
      ];
    };
    # fzf binary for fzf-tab. No zsh integration: its Ctrl-R would replace atuin's.
    fzf = {
      enable = true;
      enableZshIntegration = false;
    };
    home-manager.enable = true;
  };

}
