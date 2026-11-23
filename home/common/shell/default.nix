{
  lib,
  meta,
  ...
}:
{
  imports = [
    ./atuin.nix
    ./bat.nix
    ./btop.nix
    ./omp
    ./fastfetch.nix
    ./nh.nix
    ./nix-index.nix
    ./ssh.nix
    ./zellij.nix
    ./zsh.nix
    ../programs/nixvim
    ./git.nix
  ]
  ++ lib.optional meta.isDesktop ./xdg.nix;

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
      # 16-colour scheme follows the terminal palette; pointer/cursor line moved off red/bright-black.
      defaultOptions = [
        "--color=16,bg+:0,gutter:0,hl:3,hl+:3,pointer:3,marker:3,prompt:3,info:8,spinner:8,scrollbar:8"
      ];
    };
    # Standalone Home Manager only; the darwin module manages itself.
    home-manager.enable = !meta.isDarwin;
  };

}
