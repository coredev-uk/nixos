{ pkgs, meta, ... }:
{
  hardware.openrazer = {
    enable = true;
    batteryNotifier = {
      enable = true;
      percentage = 20;
    };
    users = [ meta.username ];
  };

  environment.systemPackages = with pkgs; [
    polychromatic
  ];
}
