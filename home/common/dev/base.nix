{
  pkgs,
  meta,
  ...
}:
{
  catppuccin.k9s.enable = true;
  programs = {

    # Kubernetes CLI
    k9s.enable = true;

    # Node
    bun.enable = true;

    # env
    direnv = {
      enable = true;
      enableZshIntegration = true;
      mise.enable = true;
    };
    mise = {
      enable = true;
      enableZshIntegration = true;
      globalConfig = {
        env.PYTHON_CONFIGURE_OPTS = "--without-ensurepip";
        env.MISE_DISABLE_TOOLS = "python";
        settings = {
          all_compile = false;
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
      # Wrapper
      nixfmt-plus
      nixfmt
      nurl
      statix

      # Python tooling
      (pkgs.python3.withPackages (
        p: with p; [
          virtualenv
          pyserial
          distutils
        ]
      ))
      pipx

      # Shell tooling
      shellcheck
      shfmt
      # binutils

      # Kubernetes
      kubectl
      kubernetes-helm
      kubeconform
      fluxcd
      talosctl
      sops

      # env
      devenv
    ]
    ++ lib.optionals meta.isDesktop [
      # Tauri
      webkitgtk_4_1
      pkg-config
      openssl

      # Electron
      dpkg
      fakeroot
      rpm
      libglibutil
    ];
}
