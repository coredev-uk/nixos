{
  pkgs,
  meta,
  ...
}:
let
  plexDesktop = pkgs.plex-desktop.override {
    extraEnv = {
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
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
    ../programs/discord.nix
    ../programs/element.nix
    ../programs/gaming.nix
    ../programs/ghostty.nix
    ../programs/zen.nix
    # ./programs/rclone.nix
  ];

  home.packages = with pkgs; [
    brave
    # cider-2
    desktop-file-utils
    file-roller
    plexDesktop
    loupe
    mpv
    nautilus
    proton-vpn-cli
    papers
  ];

}
