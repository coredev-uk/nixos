{
  pkgs,
  meta,
  inputs,
  self,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  stripHash = str: builtins.substring 1 (-1) str;
in
{
  programs.mangohud = {
    enable = true;

    settings = {
      table_columns = 2;
      hud_compact = true;
      width = 150;

      ## Background
      round_corners = 5;
      background_alpha = 0.4;
      background_color = stripHash theme.colours.mantle;

      ## Text
      font_size = 20;
      text_outline = true;
      text_outline_color = stripHash theme.colours.crust;
      text_outline_thickness = 1.5;
      text_color = stripHash theme.colours.text;

      fps = true;
      fps_color_change = true;
      fps_value = "60,144";
      fps_color = "${stripHash theme.colours.red},${stripHash theme.colours.yellow},${stripHash theme.colours.green}";
      fps_sampling_period = 500;
      fps_metrics = "avg,0.01";

      frametime = false;
      frame_timing = false;
      gpu_stats = false;
      cpu_stats = false;

      ## Toggle hotkeys
      toggle_hud = "Shift_R+F12";
      toggle_fps_limit = "Shift_L+F1";
    };
  };

  home.packages = with pkgs; [
    beammp-launcher
    heroic-unwrapped
    (inputs.nix-citizen.packages.${meta.system}.rsi-launcher.override {
      location = "$HOME/games/Star Citizen";
      extraEnvVars = {
        MANGOHUD = 1;
      };
    })
    umu-launcher
    vulkan-tools
    wineWowPackages.staging
    winetricks
  ];
}
