{
  lib,
  pkgs,
  meta,
  self,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  imports = [
    ../default/wayland.nix
    ../../programs/hypr
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # Hyprland, XWayland and the portal come from the NixOS module (hosts/common/desktop/hyprland.nix).
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
        # Through logind, so hypridle's lock_cmd starts the one lock screen.
        lock = "loginctl lock-session";
        animations = import ./config/animations.nix { inherit luaCall; };

        # Hyprland colour strings from the Meridian palette: "#rrggbb" -> "rgb(rrggbb)".
        color = name: "rgb(${lib.removePrefix "#" theme.meridian.${name}})";
      in
      {
        monitor = (import ./config/monitors.nix { })."${meta.hostname}";

        # The 1Password app starts hidden, as it serves the SSH agent, the browser integration
        # and the unlock prompts. Proton Pass needs no app running: the SSH agent is a pass-cli
        # service (home/common/shell/ssh.nix), the extension stands alone, and the desktop app
        # has no start-hidden or start-at-login option on Linux.
        on = lib.mkIf (meta.passwordManager == "1password") {
          _args = [
            "hyprland.start"
            (lua ''
              function()
                hl.exec_cmd("uwsm app -- 1password --silent")
              end
            '')
          ];
        };

        config = {
          general = {
            gaps_in = 0; # 5
            gaps_out = 0; # 5
            border_size = 2; # 0

            col = {
              active_border = color "gilt";
              inactive_border = color "rule";
            };

            allow_tearing = true;
            layout = "dwindle";
          };

          # Tabbed groups (SUPER+W). The groupbar has no background of its own: without
          # gradients only the titles and a thin indicator are drawn, so the strip above the
          # window showed the wallpaper. Filled tabs, no upper gap, flush with the window.
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
              rounding = 4; # match decoration.rounding
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
            # Rounding
            rounding = 4;

            # Opacity
            active_opacity = 1.0;
            inactive_opacity = 0.95;

            # Blur
            blur = {
              enabled = true;
              size = 3;
              passes = 2;
            };
          };

          animations = {
            enabled = true;
          };

          # https://wiki.hypr.land/Configuring/Variables/#misc
          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            # If the lock screen crashes, `quickshell-lock` from a TTY (with WAYLAND_DISPLAY and
            # HYPRLAND_INSTANCE_SIGNATURE set) can take the session over again.
            allow_session_lock_restore = true;
            # Input wakes monitors that hypridle switched off.
            key_press_enables_dpms = true;
            mouse_move_enables_dpms = true;
            # Games and long loads stall for seconds; the dialog only gets in the way.
            enable_anr_dialog = false;
          };

          dwindle.preserve_split = true;

          # Direct scanout for fullscreen windows with the game content type only (2 = auto).
          render.direct_scanout = 2;

          ecosystem = {
            no_update_news = true;
            no_donation_nag = true;
          };

          # debug = {
          #   disable_logs = true;
          # };
        };

        layer_rule = [
          {
            match.namespace = "bar";
            blur = true;
            ignore_alpha = 0.5;
          }
          # Secrets-bearing surfaces stay black in screen shares and recordings.
          {
            match.namespace = "^(notifications|pass-quick-access|polkit)$";
            no_screen_share = true;
          }
          # The shell animates these itself and keeps them mapped between showings; a fade of
          # the whole surface on top would double up on map and come too late on unmap.
          {
            match.namespace = "^(osd|notifications|screenshot)$";
            no_anim = true;
          }
        ];

        # Primary (DP-1) takes workspaces 1-5, the secondary (DP-2) 6-10 (config/monitors.nix).
        workspace_rule = lib.optionals (meta.hostname == "atlas") (
          lib.genList (i: {
            workspace = toString (i + 1);
            monitor = if i < 5 then "DP-1" else "DP-2";
            default = i == 0 || i == 5;
          }) 10
        );

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
                ;
            })
          )
          bind
          ;
      };
  };

  # Nvidia Variables
  home.sessionVariables.LIBVA_DRIVER_NAME = "nvidia";
}
