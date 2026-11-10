{ pkgs, ... }:
{
  # pamu2fcfg registers a key for pam_u2f (hosts/common/desktop/default.nix).
  environment.systemPackages = with pkgs; [
    yubikey-manager
    pam_u2f
  ];

  services = {
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
  };
}
