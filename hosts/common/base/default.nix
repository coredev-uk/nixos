{
  pkgs,
  lib,
  meta,
  ...
}:
{
  imports = [
    ./boot.nix
    ./console.nix
    ./hardware.nix
    ./locale.nix
    ./zramswap.nix

    ../services/fail2ban.nix
    ../services/openssh.nix
  ];

  networking = {
    hostName = meta.hostname;
    useDHCP = lib.mkDefault true;
  };

  environment.systemPackages = (import ./packages.nix { inherit pkgs; }).basePackages;

  programs = {
    zsh.enable = true;
  };

  services = {
    # chrony.enable = true;
    journald.extraConfig = lib.mkDefault "SystemMaxUse=250M";
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
    sudo.wheelNeedsPassword = lib.mkDefault true;
  };

  # Create dirs for home-manager
  systemd.tmpfiles.rules = [
    "d /nix/var/nix/profiles/per-user/${meta.username} 0755 ${meta.username} root"
  ];
}
