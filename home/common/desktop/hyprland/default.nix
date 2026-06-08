{
  lib,
  pkgs,
  meta,
  ...
}:
{
  imports = [
    ../default/wayland.nix
    ../../programs/hypr
  ];

  catppuccin.hyprland.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    xwayland.enable = true;

    # Fix weird environment variable bs
    systemd.variables = [ "--all" ];

    settings =
      let
        lua = lib.generators.mkLuaInline;
        luaCall = args: { _args = args; };
        mod = "SUPER";
        browser = "zen-twilight";
        terminal = "${pkgs.ghostty}/bin/ghostty";
        menu = "vicinae open"; # rofi -show drun";
        lock = "${pkgs.hyprlock}/bin/hyprlock";
        wallpaper = pkgs.writeScriptBin "get-wallpaper" (builtins.readFile ../../scripts/wallpaper.sh);
        animations = import ./config/animations.nix { inherit luaCall; };
      in
      {
        monitor = (import ./config/monitors.nix { })."${meta.hostname}";

        on = {
          _args = [
            "hyprland.start"
            (lua ''
              function()
                hl.exec_cmd("eww open-many bar bar-second")
                hl.exec_cmd(${builtins.toJSON ''hyprctl hyprpaper wallpaper " , $(${wallpaper}/bin/get-wallpaper), cover"''})
                hl.exec_cmd("1password --silent")
              end
            '')
          ];
        };

        config = {
          general = {
            gaps_in = 0; # 5
            gaps_out = 0; # 5
            border_size = 2; # 0

            allow_tearing = true;
            layout = "dwindle";
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
              new_optimizations = true;
            };
          };

          animations = {
            enabled = true;
          };

          master = {
            new_status = "master";
          };

          # https://wiki.hypr.land/Configuring/Variables/#misc
          misc = {
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          # debug = {
          #   disable_logs = true;
          # };
        };

        layer_rule = [
          {
            match.namespace = "bar";
            blur = true;
          }
          {
            match.namespace = "rofi";
            no_anim = true;
          }
          {
            match.namespace = "discord";
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
                wallpaper
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
  home.sessionVariables.__GLX_VENDOR_LIBRARY_NAME = "nvidia";
  home.sessionVariables.NVD_BACKEND = "direct";
}
