{
  lib,
  pkgs,
  meta,
  theme,
  ...
}:
{
  imports = [
    ../default/wayland.nix
    ../../programs/hypr
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # Hyprland, XWayland and portal come from the NixOS module (hosts/common/desktop/hyprland.nix).
    package = null;
    portalPackage = null;

    # uwsm owns the systemd session and environment export; HM's hyprland-session.target conflicts.
    systemd.enable = false;

    settings =
      let
        lua = lib.generators.mkLuaInline;
        luaCall = args: { _args = args; };
        mod = "SUPER";
        browser = "zen-twilight";
        terminal = "${pkgs.ghostty}/bin/ghostty";
        menu = "vicinae open";
        # Via logind so hypridle's lock_cmd runs the one lock screen.
        lock = "loginctl lock-session";
        animations = import ./config/animations.nix { inherit luaCall; };

        # Zen (Firefox) quits with its last window on Linux and can't start windowless (-silent
        # exits). Its main window is parked in special:browser instead of closed, so links open as
        # Little Zen windows of the running instance instead of launching the full browser. Lua
        # snippets over a window expression; the class is the command name.
        zen = rec {
          isMain = w: ''(${w}.class == "${browser}" and ${w}.initial_title ~= "Little Zen")'';
          park =
            w:
            ''hl.dispatch(hl.dsp.window.move({ window = ${w}, workspace = "special:browser", follow = false }))'';
          # Closes w unless it's the last main window (extra windows, Picture-in-Picture).
          close = w: ''
            local others = 0
            for _, o in ipairs(hl.get_windows()) do
              if o.address ~= ${w}.address and ${isMain "o"} then others = others + 1 end
            end
            if others > 0 then hl.dispatch(hl.dsp.window.close({ window = ${w} })) else ${park w} end
          '';
        };

        # "#rrggbb" -> "rgb(rrggbb)"
        color = name: "rgb(${lib.removePrefix "#" theme.meridian.${name}})";
      in
      {
        monitor = meta.monitors;

        on =
          let
            # Zen's Close Window (Ctrl+Shift+W) acts like Super+Q on its main windows; bound only
            # while one is focused so other apps keep the shortcut. A reload drops runtime binds.
            bindZenClose = lua ''
              function()
                hl.unbind("CTRL + SHIFT + W")
                local active = hl.get_active_window()
                if active and ${zen.isMain "active"} then
                  hl.bind("CTRL + SHIFT + W", function()
                    local w = hl.get_active_window()
                    if w then ${zen.close "w"} end
                  end)
                end
              end
            '';
          in
          [
            (luaCall [
              "hyprland.start"
              (lua ''
                function()
                  -- Proton Pass serves the SSH agent (shell/ssh.nix), so it runs from login. It
                  -- always shows its window on Linux: close the first one (hides to tray); the 60 s
                  -- limit avoids closing a manual launch if none appears.
                  local passWindow
                  passWindow = hl.on("window.open", function(w)
                    if w.class == "proton-pass" then
                      passWindow:remove()
                      hl.dispatch(hl.dsp.window.close({ window = w }))
                    end
                  end)
                  hl.timer(function() passWindow:remove() end, { timeout = 60000, type = "oneshot" })
                  hl.exec_cmd("uwsm app -- proton-pass")

                  -- Proton Mail has no tray and quits on window close: it lives in the special:mail
                  -- scratchpad (window-rules.nix), shown with Super+M (keybindings.nix).
                  hl.exec_cmd("uwsm app -- proton-mail")

                  -- Zen starts parked; Super+B shows or parks it (keybindings.nix).
                  hl.exec_cmd("uwsm app -- ${browser}", { workspace = "special:browser silent" })
                end
              '')
            ])
            (luaCall [
              "window.active"
              bindZenClose
            ])
            (luaCall [
              "config.reloaded"
              bindZenClose
            ])
          ];

        config = {
          general = {
            gaps_in = 0;
            gaps_out = 0;
            border_size = 2;

            col = {
              active_border = color "gilt";
              inactive_border = color "rule";
            };

            allow_tearing = true;
            layout = "dwindle";
          };

          # Tabbed groups (SUPER+W). Without gradients the groupbar draws no background and shows
          # the wallpaper; use filled tabs flush with the window.
          group = {
            col = {
              border_active = color "gilt";
              border_inactive = color "rule";
              border_locked_active = color "caution";
              border_locked_inactive = color "muted";
            };

            groupbar = {
              gradients = true;
              height = 20;
              indicator_height = 0;
              keep_upper_gap = false;
              gaps_in = 0;
              gaps_out = 0;
              rounding = 4; # = decoration.rounding
              gradient_rounding = 4;
              round_only_edges = true;
              gradient_round_only_edges = true;

              font_family = theme.fonts.shell.name;
              font_size = 11;
              font_weight_active = "semibold";
              text_color = color "gilt";
              text_color_inactive = color "text2";
              text_color_locked_active = color "caution";
              text_color_locked_inactive = color "muted";

              col = {
                active = color "rule";
                inactive = color "inset";
                locked_active = color "rule";
                locked_inactive = color "inset";
              };
            };
          };

          input = {
            kb_layout = "gb";
            follow_mouse = 1;
            sensitivity = 0;
            accel_profile = "flat";
          };

          decoration = {
            rounding = 4;

            active_opacity = 1.0;
            inactive_opacity = 0.95;

            blur = {
              enabled = true;
              size = 3;
              passes = 2;
            };
          };

          animations = {
            enabled = true;
          };

          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            # Recover a crashed lock screen: run `quickshell-lock` from a TTY (WAYLAND_DISPLAY and HYPRLAND_INSTANCE_SIGNATURE set).
            allow_session_lock_restore = true;
            # Input wakes monitors hypridle turned off.
            key_press_enables_dpms = true;
            mouse_move_enables_dpms = true;
            # Stalls in games/long loads trigger it needlessly.
            enable_anr_dialog = false;
          };

          dwindle.preserve_split = true;

          # Direct scanout only for game content type (2 = auto).
          render.direct_scanout = 2;

          ecosystem = {
            no_update_news = true;
            no_donation_nag = true;
          };
        };

        layer_rule = [
          {
            match.namespace = "bar";
            blur = true;
            ignore_alpha = 0.5;
          }
          # Secret-bearing surfaces: black in screen shares and recordings.
          {
            match.namespace = "^(notifications|pass-quick-access|polkit)$";
            no_screen_share = true;
          }
          # The shell animates these itself; a compositor fade would double up.
          {
            match.namespace = "^(osd|notifications|screenshot)$";
            no_anim = true;
          }
        ];

        inherit (animations) curve animation;

        window_rule = (import ./config/window-rules.nix { }).window;

        inherit
          (
            (import ./config/keybindings.nix {
              inherit
                browser
                lock
                menu
                mod
                pkgs
                terminal
                lua
                luaCall
                zen
                ;
            })
          )
          bind
          ;
      };
  };

  # Zen's main window is parked rather than closed (the zen helpers above): Ctrl+W on the empty tab
  # doesn't close the window, and no close button (min/max mean nothing when tiled either).
  programs.zen-browser.profiles.default.settings = {
    "zen.tabs.close-window-with-empty" = false;
    "zen.view.experimental-no-window-controls" = true;
  };

  # Hyprland on Nvidia
  home.sessionVariables.LIBVA_DRIVER_NAME = "nvidia";
}
