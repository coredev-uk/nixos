{ pkgs, config, ... }:

{
  imports = [
    ../../programs/quickshell
    ../../programs/swaync.nix
    ../../programs/vicinae.nix
  ];

  home.packages = with pkgs; [
    libnotify
    wl-clipboard
    wdisplays
    hyprprop
  ];

  fonts.fontconfig.enable = true;
  services = {
    hyprpolkitagent.enable = true;
    swayosd.enable = true;
  };

  # uwsm sources this into the session and exports the result to the systemd user manager,
  # so home.sessionVariables reach the compositor, user services and launched apps.
  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  home.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";
    CLUTTER_BACKEND = "wayland";
    # Fall back to X11 (XWayland) for clients/runtimes without Wayland support.
    GDK_BACKEND = "wayland,x11,*";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland,x11";
    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
  };
}
