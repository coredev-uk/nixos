{
  pkgs,
  meta,
  ...
}:
{
  imports = [
    ../wl-common.nix
    ./packages.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    # Fix weird environment variable bs
    systemd.variables = [ "--all" ];

    settings =
      let
        mod = "Mod4";
        browser = "zen";
        terminal = "${pkgs.ghostty}/bin/ghostty";
        menu = "rofi -show drun";
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

          "col.active_border" = "rgba(f2cdcdff) rgba(cba6f7ff) 45deg";
          "col.inactive_border" = "rgba(595959aa)";

          allow_tearing = false;
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
          "1password --silent"
          "${wallpaper}/bin/get-wallpaper --session=hyprland"
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

        bezier = [
          "mycurve,.32,.97,.53,.98"
        ];

        animations = {
          enabled = 0;
          animation = [
            "windowsMove,1,4,mycurve"
            "windowsIn,1,4,mycurve"
            "windowsOut,0,4,mycurve"
          ];
        };

        windowrulev2 = (import ./config/window-rules.nix { }).window_v2;

        debug = {
          disable_logs = true;
        };

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
