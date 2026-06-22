{ inputs, meta, ... }:
{
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  catppuccin.vicinae.enable = true;

  programs.vicinae = {
    enable = true;

    package = inputs.vicinae.packages.${meta.system}.default;

    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };

  };
}
