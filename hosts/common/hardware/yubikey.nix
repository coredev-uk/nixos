{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    yubikey-manager
    pam_u2f
  ];

  services = {
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
  };
}
