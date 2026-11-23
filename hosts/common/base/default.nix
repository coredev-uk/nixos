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
  # Bare metal only: WSL has its own kernel, swap, no VT/firmware, no SSH.
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
    journald.extraConfig = lib.mkDefault "SystemMaxUse=250M";

    # LVFS firmware; UEFI capsule updates need fwupd's EFI binary signed with lanzaboote's keys.
    fwupd.enable = !meta.isWSL;
  };

  # No sudo.execWheelOnly: btrbk runs as its own user and needs sudo for btrfs.
  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  # home-manager profile dir
  systemd.tmpfiles.rules = [
    "d /nix/var/nix/profiles/per-user/${meta.username} 0755 ${meta.username} root"
  ];
}
