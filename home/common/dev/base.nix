{
  pkgs,
  meta,
  ...
}:
{

  # Kubernetes CLI Tool
  programs.k9s.enable = true;
  catppuccin.k9s.enable = true;

  programs.bun.enable = true;

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
