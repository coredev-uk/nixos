{ pkgs, config, ... }:

{
  # Bar, notifications, OSD, polkit agent, lock screen and wallpaper are all Quickshell.
  imports = [
    ../../programs/quickshell
    ../../programs/airplay.nix
    ../../programs/vicinae
  ];

  home.packages = with pkgs; [
    libnotify
    wl-clipboard
    wdisplays
    hyprprop
  ];

  fonts.fontconfig.enable = true;

  # uwsm exports this to the systemd user manager so sessionVariables reach the compositor and apps.
  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  home.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
    # X11 fallback.
    GDK_BACKEND = "wayland,x11,*";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    NIXOS_OZONE_WL = "1";
  };
}
