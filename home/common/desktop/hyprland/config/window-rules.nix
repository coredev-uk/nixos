_: {
  window = [
    # Floating Windows
    "float true, match:class ^$, match:title ^$"
    "no_focus true, match:class ^$, match:title ^$"

    # Miscellaneous
    "center true, match:class ^(polkit-gnome-authentication-agent-1)$"
    "center true, match:title ^(.*notificationtoasts*.)$"

    # Picture-in-Picture
    "float true, match:title ^(Picture-in-Picture|Firefox)$"
    "size 800 450, match:title ^(Picture-in-Picture|Firefox)$"
    "pin true, match:title ^(Picture-in-Picture|Firefox)$"
    "move 100%-850 100%-500, match:title ^(Picture-in-Picture|Firefox)$"

    # Wine
    "move 0 0, match:title ^(Wine System Tray)$"
    "size 0 0, match:title ^(Wine System Tray)$"

    # --- Steam Client Rules ---
    # Float everything that isn't the main Steam window
    "float true, match:class ^(steam)$"
    "tile true, match:class ^(steam)$, match:title ^Steam$"

    # Center specific Steam windows
    "center true, match:class ^(steam)$, match:title ^(Steam Settings)$"
    "center true, match:class ^(steam)$, match:title ^(Friends List)$"

    # Fix Steam menus/popups disappearing
    "stay_focused true, match:title ^()$, match:class ^(steam)$"
    "min_size 1 1, match:title ^()$, match:class ^(steam)$"

    # --- Steam Game Rules ---
    # Matches any window with class 'steam_app_NUMBER'

    # Force games to be fullscreen
    "fullscreen true, match:class ^(steam_app_\\d+)$"

    # Prevent screen from turning off while playing
    "idle_inhibit focus, match:class ^(steam_app_\\d+)$"

    # Allow tearing (low latency) for games
    "immediate true, match:class ^(steam_app_\\d+)$"

    # xwaylandvideobridge
    "opacity 0.0 override, match:class ^(xwaylandvideobridge)$"
    "no_anim true, match:class ^(xwaylandvideobridge)$"
    "no_focus true, match:class ^(xwaylandvideobridge)$"
    "max_size 1 1, match:class ^(xwaylandvideobridge)$"
    "no_blur true, match:class ^(xwaylandvideobridge)$"
  ];
}
