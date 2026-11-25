{
  config,
  lib,
  pkgs,
  theme,
  ...
}:
let
  m = theme.meridian;
  stripHash = str: builtins.substring 1 (-1) str;
in
{
  programs.mangohud = {
    enable = true;

    settings = {
      table_columns = 2;
      hud_compact = true;
      width = 150;

      round_corners = 5;
      background_alpha = 0.4;
      background_color = stripHash m.plate;

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

      toggle_hud = "Shift_R+F12";
      toggle_fps_limit = "Shift_L+F1";
    };
  };

  # BeamMP launcher must stay open and only logs, so run it in Ghostty (x-scheme-handler/terminal is
  # unset, so Terminal=true wouldn't work). Icon is Steam's BeamNG.drive one.
  xdg.desktopEntries.beammp-launcher = {
    name = "BeamMP";
    comment = "Launcher for the BeamMP mod for BeamNG.drive";
    exec = "${lib.getExe config.programs.ghostty.package} --title=BeamMP -e ${lib.getExe pkgs.beammp-launcher}";
    icon = "steam_icon_284160";
    categories = [ "Game" ];
  };

  # Sunshine runs as a user service (hosts/common/desktop/gaming.nix). Its own entry starts a second,
  # unprivileged server that fights the service for its ports; this one opens the service's web UI.
  xdg.desktopEntries."dev.lizardbyte.app.Sunshine" = {
    name = "Sunshine";
    comment = "Game stream host for Moonlight";
    exec = "${pkgs.writeShellScript "sunshine-ui" ''
      systemctl --user start sunshine.service
      exec ${pkgs.xdg-utils}/bin/xdg-open https://localhost:47990
    ''}";
    icon = "dev.lizardbyte.app.Sunshine";
    categories = [ "Game" ];
  };

  home.packages = with pkgs; [
    beammp-launcher
    heroic
    r2modman
    umu-launcher
    vulkan-tools
    wineWow64Packages.staging
    winetricks
  ];
}
