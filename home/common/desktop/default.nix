{
  pkgs,
  meta,
  ...
}:
let
  plexDesktop = pkgs.plex-desktop.override {
    extraEnv = {
      LIBVA_DRIVER_NAME = "nvidia";
      QT_OPENGL = "desktop";
      QT_QPA_PLATFORM = "xcb";
      QT_XCB_GL_INTEGRATION = "xcb_glx";
      VDPAU_DRIVER = "nvidia";
    };
  };
in
{
  imports = [
    (./. + "/${meta.desktop}")

    # Environment Configurations
    ./default/gtk.nix
    ./default/qt.nix
    ./default/xdg.nix

    ../scripts

    # Standard Programs
    ../programs/cider
    ../programs/discord.nix
    ../programs/gaming.nix
    ../programs/ghostty.nix
    ../programs/zen.nix
  ];

  home.packages = with pkgs; [
    brave
    desktop-file-utils
    file-roller
    plexDesktop
    loupe
    mpv
    nautilus
    papers
    # unstable.proton-drive-cli # TODO: needs to be merged into unstable... @SEE https://github.com/NixOS/nixpkgs/pull/557198
    protonmail-desktop
    proton-pass
    proton-pass-cli
    proton-vpn-cli
  ];

  # pass-cli keeps its session key in the kernel keyring by default, which is denied here and
  # wiped on reboot; gnome-keyring (unlocked at login) keeps it instead.
  home.sessionVariables.PROTON_PASS_LINUX_KEYRING = "dbus";
}
