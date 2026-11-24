_: {
  window = [
    # XWayland dialogs/menus without class or title: don't take focus
    {
      match = {
        class = "^$";
        title = "^$";
        xwayland = true;
      };
      no_focus = true;
    }

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

    # Screen cast picker (from the bar's Connections panel): small floating window
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

    # Picture-in-Picture: bottom-right, 50px from the edges
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

    # Little Zen (links from other apps): a centred popup over the current workspace
    {
      match = {
        class = "^(zen-twilight)$";
        initial_title = "^(Little Zen)$";
      };
      float = true;
      size = [
        "monitor_w*0.5"
        "monitor_h*0.7"
      ];
      center = true;
    }

    # Collapse the Wine tray window
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

    # Steam: float everything but the main window
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

    # Menus/popups vanish otherwise
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

    # Games: class steam_app_<id>
    {
      match.class = "^(steam_app_\\d+)$";
      fullscreen = true;
    }

    {
      match.class = "^(steam_app_\\d+)$";
      idle_inhibit = "focus";
    }

    # Tearing for low latency
    {
      match.class = "^(steam_app_\\d+)$";
      immediate = true;
    }

    # Keep out of screen shares and recordings
    {
      match.class = "^(Proton Pass|proton-pass|proton-pass-desktop)$";
      no_screen_share = true;
    }

    # Lives in the scratchpad (Super+M, keybindings.nix)
    {
      match.class = "^(proton-mail)$";
      workspace = "special:mail silent";
    }

    # Stay opaque when unfocused (e.g. while screensharing)
    {
      match.class = "^(discord)$";
      opacity = "1.0 override 1.0 override";
    }
  ];
}
