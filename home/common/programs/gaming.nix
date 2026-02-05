{ pkgs, ... }:
{
  catppuccin.mangohud.enable = true;

  programs = {
    mangohud = {
      enable = true;

      settings = {
        table_columns = 2;
        hud_compact = true;
        gpu_stats = true;
        cpu_stats = true;
        fps = true;
        frametime = false;
        frame_timing = false;
        round_corners = 3;
        width = 100;
      };
    };

    lutris = {
      enable = true;
      extraPackages = with pkgs; [
        corefonts
        gamescope
        winetricks
      ];
      winePackages = with pkgs.wineWowPackages; [
        staging
      ];
    };
  };

  home.packages = with pkgs; [
    beammp-launcher
    vulkan-tools
  ];
}
