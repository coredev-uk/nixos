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
      # terminal's palette. FZF_DEFAULT_OPTS, which fzf-tab reads too.
      defaultOptions = [ "--color=16" ];
    };
    home-manager.enable = true;
  };

}
