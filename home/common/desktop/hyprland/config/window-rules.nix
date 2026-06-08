_: {
  window = [
    # Floating Windows
    {
      match = {
        class = "^$";
        title = "^$";
      };
      float = true;
    }
    {
      match = {
        class = "^$";
        title = "^$";
      };
      no_focus = true;
    }

    # Miscellaneous
    {
      match.class = "^(polkit-gnome-authentication-agent-1)$";
      center = true;
    }
    {
      match.title = "^(.*notificationtoasts*.)$";
      center = true;
    }

    # Picture-in-Picture
    {
      match.title = "^(Picture-in-Picture|Firefox)$";
      float = true;
    }
    {
      match.title = "^(Picture-in-Picture|Firefox)$";
      size = [
        800
        450
      ];
    }
    {
      match.title = "^(Picture-in-Picture|Firefox)$";
      pin = true;
    }
    {
      match.title = "^(Picture-in-Picture|Firefox)$";
      move = [
        "100%-850"
        "100%-500"
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

    # xwaylandvideobridge
    {
      match.class = "^(xwaylandvideobridge)$";
      opacity = "0.0 override";
    }
    {
      match.class = "^(xwaylandvideobridge)$";
      no_anim = true;
    }
    {
      match.class = "^(xwaylandvideobridge)$";
      no_focus = true;
    }
    {
      match.class = "^(xwaylandvideobridge)$";
      max_size = [
        1
        1
      ];
    }
    {
      match.class = "^(xwaylandvideobridge)$";
      no_blur = true;
    }
  ];
}
