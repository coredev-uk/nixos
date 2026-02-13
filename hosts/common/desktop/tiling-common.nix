{ pkgs, ... }:
{
  programs = {
    dconf.enable = true;
  };

  environment = {
    # variables.NIXOS_OZONE_WL = "1";

    systemPackages = with pkgs; [
      zenity
      # Enable HEIC image previews in Nautilus
      libheif
      libheif.out
      # Required for Electron apps to use gnome-keyring for password storage
      libsecret
    ];

    # Enable HEIC image previews in Nautilus
    pathsToLink = [ "share/thumbnailers" ];
  };

  services = {
    dbus = {
      enable = true;
      implementation = "broker";
    };

    gnome = {
      gnome-keyring.enable = true;
      sushi.enable = true;
    };

    greetd = {
      enable = true;
      restart = false;
    };

    gvfs.enable = true;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];

    config = {
      common = {
        default = [
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [
          "gnome-keyring"
        ];
      };

      # Hyprland-specific portal configuration
      Hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        # Use hyprland portal for screencasting/screenshots
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.GlobalShortcuts" = [ "hyprland" ];
        # Use GTK portal for file operations and URI opening
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
        # Secret handling via gnome-keyring
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
  };
}
