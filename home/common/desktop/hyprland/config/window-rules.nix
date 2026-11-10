_: {
  window = [
    # XWayland dialogs/menus without class or title: leave focus where it is
    {
      match = {
        class = "^$";
        title = "^$";
        xwayland = true;
      };
      no_focus = true;
    }

    # Miscellaneous
    {
      match.class = "^(zenity)$";
      float = true;
    }
    {
      match.class = "^(zenity)$";
      center = true;
    }
    {
      match.title = "^(.*notificationtoasts*.)$";
      center = true;
    }

    # Screen casting (opened from the bar's Connections panel): a small picker, not a tiled window.
    {
      match.class = "^(org\\.gnome\\.NetworkDisplays)$";
      float = true;
    }
    {
      match.class = "^(org\\.gnome\\.NetworkDisplays)$";
      size = [
        480
        560
      ];
    }
    {
      match.class = "^(org\\.gnome\\.NetworkDisplays)$";
      center = true;
    }

    # Picture-in-Picture: bottom-right corner, 50px in from the monitor edges
    {
      match.title = "^(Picture-in-Picture)$";
      float = true;
      pin = true;
      size = [
        800
        450
      ];
      move = [
        "monitor_w-window_w-50"
        "monitor_h-window_h-50"
      ];
    }

    # Wine
    {
      match.title = "^(Wine System Tray)$";
      move = [
        0
        0
      ];
    }
    {
      match.title = "^(Wine System Tray)$";
      size = [
        0
        0
      ];
    }

    # --- Steam Client Rules ---
    # Float everything that isn't the main Steam window
    {
      match.class = "^(steam)$";
      float = true;
    }
    {
      match = {
        class = "^(steam)$";
        title = "^Steam$";
      };
      tile = true;
    }

    # Center specific Steam windows
    {
      match = {
        class = "^(steam)$";
        title = "^(Steam Settings)$";
      };
      center = true;
    }
    {
      match = {
        class = "^(steam)$";
        title = "^(Friends List)$";
      };
      center = true;
    }

    # Fix Steam menus/popups disappearing
    {
      match = {
        title = "^()$";
        class = "^(steam)$";
      };
      stay_focused = true;
    }
    {
      match = {
        title = "^()$";
        class = "^(steam)$";
      };
      min_size = [
        1
        1
      ];
    }

    # --- Steam Game Rules ---
    # Matches any window with class 'steam_app_NUMBER'

    # Force games to be fullscreen
    {
      match.class = "^(steam_app_\\d+)$";
      fullscreen = true;
    }

    # Prevent screen from turning off while playing
    {
      match.class = "^(steam_app_\\d+)$";
      idle_inhibit = "focus";
    }

    # Allow tearing (low latency) for games
    {
      match.class = "^(steam_app_\\d+)$";
      immediate = true;
    }

    # Keep the password managers out of screen shares and recordings
    {
      match.class = "^(1Password|Proton Pass|proton-pass|proton-pass-desktop)$";
      no_screen_share = true;
    }

    # Keep Discord fully opaque when unfocused (general:inactive_opacity), e.g. while screensharing
    {
      match.class = "^(discord)$";
      opacity = "1.0 override 1.0 override";
    }
  ];
}
