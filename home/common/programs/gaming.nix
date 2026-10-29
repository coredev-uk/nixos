{
  pkgs,
  self,
  ...
}:
let
  m = (import "${self}/lib/theme" { inherit pkgs; }).meridian;
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
      background_color = stripHash m.plate;

      ## Text
      font_size = 20;
      text_outline = true;
      text_outline_color = stripHash m.ground;
      text_outline_thickness = 1.5;
      text_color = stripHash m.text;

      fps = true;
      fps_color_change = true;
      fps_value = "60,144";
      fps_color = "${stripHash m.alert},${stripHash m.caution},${stripHash m.ok}";
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
    heroic
    r2modman
    umu-launcher
    vulkan-tools
    wineWow64Packages.staging
    winetricks
  ];
}
