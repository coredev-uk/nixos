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
      # fzf's own default scheme is fixed 256-colour values; the 16-colour one follows the
      # terminal's palette. Its red pointer and bright-black cursor line are moved to yellow
      # and black (ANSI 3 and 0), so red stays for errors. FZF_DEFAULT_OPTS, which fzf-tab
      # reads too.
      defaultOptions = [
        "--color=16,bg+:0,gutter:0,hl:3,hl+:3,pointer:3,marker:3,prompt:3,info:8,spinner:8,scrollbar:8"
      ];
    };
    home-manager.enable = true;
  };

}
