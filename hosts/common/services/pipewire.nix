{
  lib,
  pkgs,
  desktop,
  ...
}:
{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  environment.systemPackages =
    if (builtins.isString desktop) then
      [
        pkgs.pwvucontrol
        pkgs.pamixer
        pkgs.playerctl
      ]
    else
      [ ];
}
