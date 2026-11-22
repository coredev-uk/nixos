{
  pkgs,
  lib,
  meta,
  ...
}:
{
  imports = [
    ./locale.nix
  ]
  # Bare metal only: WSL boots its own kernel, has no VT or firmware to manage, brings its own
  # swap, and nothing logs in to it over SSH.
  ++ lib.optionals (!meta.isWSL) [
    ./boot.nix
    ./console.nix
    ./hardware.nix
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

    nh = {
      enable = true;
      flake = meta.flakePath;
      clean = {
        enable = true;
        extraArgs = "--keep 3 --keep-since 3d";
      };
    };
  };

  services = {
    # chrony.enable = true;
    journald.extraConfig = lib.mkDefault "SystemMaxUse=250M";

    # Firmware updates from LVFS (NVMe, peripherals). UEFI capsule updates won't run under
    # lanzaboote's Secure Boot keys unless fwupd's EFI binary is signed with them.
    fwupd.enable = !meta.isWSL;
  };

  # No sudo.execWheelOnly: services.btrbk runs as the btrbk user and calls sudo for btrfs, so
  # restricting the binary to wheel stops the hourly /home snapshots.
  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  # Create dirs for home-manager
  systemd.tmpfiles.rules = [
    "d /nix/var/nix/profiles/per-user/${meta.username} 0755 ${meta.username} root"
  ];
}
