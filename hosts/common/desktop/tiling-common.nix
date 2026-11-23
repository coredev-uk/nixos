{ pkgs, ... }:
{
  programs = {
    dconf.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      zenity
      # HEIC previews in Nautilus
      libheif
      libheif.out
      # Electron password storage via gnome-keyring
      libsecret
    ];

    # Thumbnailers (HEIC previews)
    pathsToLink = [ "share/thumbnailers" ];
  };

  services = {
    gnome = {
      gnome-keyring.enable = true;
      # Would claim SSH_AUTH_SOCK; the agent is Proton Pass's (home/common/shell/ssh.nix).
      gcr-ssh-agent.enable = false;
      sushi.enable = true;
    };

    greetd = {
      enable = true;
      restart = false;
    };

    gvfs.enable = true;

    # Battery levels (Bluetooth peripherals) for quickshell and wireplumber.
    upower.enable = true;
  };

  # programs.hyprland already adds xdg-desktop-portal-gtk.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    config = {
      common = {
        default = [
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [
          "gnome-keyring"
        ];
      };

      # xdg-desktop-portal looks up <desktop>-portals.conf with XDG_CURRENT_DESKTOP lowercased.
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        # Hyprland for screencast/screenshots
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.GlobalShortcuts" = [ "hyprland" ];
        # GTK for files and URIs
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
        # Secrets via gnome-keyring
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
    };
  };
}
