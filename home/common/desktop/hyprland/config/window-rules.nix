_: {
  window_v2 = [
    # Floating Windows
    "float,class:^$,title:^$"
    "noinitialfocus,class:^$,title:^$"

    # Miscellaneous
    "center, class:^(polkit-gnome-authentication-agent-1)$"
    "center, title:^(.*notificationtoasts*.)$"

    # Picture-in-Picture
    "float, title:^(Picture-in-Picture|Firefox)$"
    "size 800 450, title:^(Picture-in-Picture|Firefox)$"
    "pin, title:^(Picture-in-Picture|Firefox)$"
    "move 100%-850 100%-500, title:^(Picture-in-Picture|Firefox)$"

    # Wine
    "move 0 0, title:^(Wine System Tray)$"
    "size 0 0, title:^(Wine System Tray)$"

    # --- Steam Client Rules ---
    # Float everything that isn't the main Steam window
    "float, class:^(steam)$, title:^(?!Steam).*$"
    "tile, class:^(steam)$, title:^Steam$"

    # Center specific Steam windows
    "center, class:^(steam)$, title:^(Steam Settings)$"
    "center, class:^(steam)$, title:^(Friends List)$"

    # Fix Steam menus/popups disappearing
    "stayfocused, title:^()$,class:^(steam)$"
    "minsize 1 1, title:^()$,class:^(steam)$"

    # --- Steam Game Rules ---
    # Matches any window with class 'steam_app_NUMBER'

    # Force games to be fullscreen
    "fullscreen, class:^(steam_app_\\d+)$"

    # Prevent screen from turning off while playing
    "idleinhibit focus, class:^(steam_app_\\d+)$"

    # Allow tearing (low latency) for games
    "immediate, class:^(steam_app_\\d+)$"

    # xwaylandvideobridge
    "opacity 0.0 override,class:^(xwaylandvideobridge)$"
    "noanim,class:^(xwaylandvideobridge)$"
    "noinitialfocus,class:^(xwaylandvideobridge)$"
    "maxsize 1 1,class:^(xwaylandvideobridge)$"
    "noblur,class:^(xwaylandvideobridge)$"

    # Jellyfin Desktop - fix flickering by disabling compositor effects
    "noblur,class:^(jellyfin-desktop)$"
    "noanim,class:^(jellyfin-desktop)$"
  ];
}
