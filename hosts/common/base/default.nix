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

    # Weekly `nh clean all`: system and every user's profiles (incl. standalone
    # home-manager), then store GC.
    nh = {
      enable = true;
      flake = meta.flakePath;
      clean = {
        enable = true;
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };
  };

  services = {
    # chrony.enable = true;
    journald.extraConfig = lib.mkDefault "SystemMaxUse=250M";

    # Firmware updates from LVFS (NVMe, peripherals). UEFI capsule updates won't run under
    # lanzaboote's Secure Boot keys unless fwupd's EFI binary is signed with them.
    fwupd.enable = true;
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  # Create dirs for home-manager
  systemd.tmpfiles.rules = [
    "d /nix/var/nix/profiles/per-user/${meta.username} 0755 ${meta.username} root"
  ];
}
