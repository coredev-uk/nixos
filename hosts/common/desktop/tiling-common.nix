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
    gnome = {
      gnome-keyring.enable = true;
      # Enabled by default with gnome-keyring; it would claim SSH_AUTH_SOCK, but the SSH agent
      # is 1Password's (home/common/shell/ssh.nix).
      gcr-ssh-agent.enable = false;
      sushi.enable = true;
    };

    greetd = {
      enable = true;
      restart = false;
      # Keeps systemd boot/status messages off tuigreet's TTY.
      useTextGreeter = true;
    };

    gvfs.enable = true;

    # Battery levels (Bluetooth peripherals) for quickshell and wireplumber.
    upower.enable = true;
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

      # Hyprland-specific portal configuration. xdg-desktop-portal lowercases
      # XDG_CURRENT_DESKTOP when looking for <desktop>-portals.conf, so the key must be too.
      hyprland = {
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
