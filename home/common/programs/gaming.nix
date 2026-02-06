{
  pkgs,
  meta,
  inputs,
  self,
  ...
}:
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
  };

  home.packages = with pkgs; [
    beammp-launcher
    heroic-unwrapped
    (inputs.nix-citizen.packages.${meta.system}.rsi-launcher.override {
      location = "$HOME/games/star-citizen";
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
