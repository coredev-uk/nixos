{
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
    xwayland.enable = true;

    # Fix weird environment variable bs
    systemd.variables = [ "--all" ];

    settings =
      let
        mod = "Mod4";
        browser = "zen-twilight";
        terminal = "${pkgs.ghostty}/bin/ghostty";
        menu = "vicinae open"; # rofi -show drun";
        lock = "${pkgs.hyprlock}/bin/hyprlock";
        wallpaper = pkgs.writeScriptBin "get-wallpaper" (builtins.readFile ../../scripts/wallpaper.sh);
      in
      {
        "$MOD" = "${mod}";

        monitor = (import ./config/monitors.nix { })."${meta.hostname}";

        general = {
          gaps_in = 0; # 5
          gaps_out = 0; # 5
          border_size = 2; # 0

          no_border_on_floating = true;

          allow_tearing = true;
          layout = "dwindle";
        };

        input = {
          kb_layout = "gb";
          follow_mouse = 1;
          sensitivity = 0;
          accel_profile = "flat";
        };

        exec-once = [
          "eww open-many bar bar-second"
          "hyprctl hyprpaper wallpaper \" , $(${wallpaper}/bin/get-wallpaper), cover\""
        ];

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

        layerrule = [
          "blur, bar"
          "noanim, rofi"
          "noanim, discord"
        ];

        animations = {
          enabled = true;
          inherit (import ./config/animations.nix { }) bezier animation;
        };

        windowrulev2 = (import ./config/window-rules.nix { }).window_v2;

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
                ;
            })
          )
          bind
          binde
          bindl
          bindm
          bindr
          ;
      };
  };

  # Nvidia Variables
  home.sessionVariables.LIBVA_DRIVER_NAME = "nvidia";
  home.sessionVariables.__GLX_VENDOR_LIBRARY_NAME = "nvidia";
  home.sessionVariables.NVD_BACKEND = "direct";
}
