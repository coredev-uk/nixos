{ pkgs, ... }:
{
  catppuccin.k9s.enable = true;
  programs = {

    # Kubernetes CLI
    k9s.enable = true;

    # env
    mise = {
      enable = true;
      enableZshIntegration = true;
      globalConfig = {
        env.PYTHON_CONFIGURE_OPTS = "--without-ensurepip";
        env.MISE_DISABLE_TOOLS = "python";
        settings = {
          all_compile = false;
          experimental = true;
        };
      };
    };

    # Git
    git.enable = true;
    lazygit = {
      enable = true;
      settings.promptToReturnFromSubprocess = false;
    };

    jq.enable = true;
  };

  home.packages =
    with pkgs;
    [
      # C++ tooling
      clang
      gnumake

      # Nix tooling
      deadnix
      nil
      nix-init
      nixfmt
      nurl
      statix
      treefmt

      # Python tooling
      (pkgs.python3.withPackages (
        p: with p; [
          virtualenv
          pyserial
        ]
      ))

      # Shell tooling
      shellcheck
      shfmt

      # Kubernetes
      kubectl
      kubernetes-helm
      fluxcd
      talosctl
      flate

      # env
      devenv
    ];
}
