{ inputs, lib, ... }:
let
  rpi = inputs.nixos-raspberrypi;
in
{
  imports = [
    rpi.nixosModules.raspberry-pi-4.base
    # nixos-raspberrypi.cachix.org, which has the vendor kernel built.
    rpi.nixosModules.trusted-nix-caches
    # Boot loader, kernel and firmware packages the modules above use.
    rpi.lib.inject-overlays
    # Card layout (FIRMWARE and NIXOS_SD) and system.build.sdImage for the first install; brings
    # NixOS's installer profile with it (rescue tools, all-hardware initrd modules).
    rpi.nixosModules.sd-image
  ];

  # Its modules read the flake from this argument (nixos-raspberrypi.lib.nixosSystem passes it).
  _module.args.nixos-raspberrypi = rpi;

  nixpkgs.hostPlatform = "aarch64-linux";

  # The SD image's profile turns on ZFS, which has no prebuilt module for the vendor kernel.
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # Bluetooth is the vendor kernel's UART driver and the Pi's firmware, no BlueZ (extra.nix). The
  # PoE+ HAT's EEPROM names its overlay (rpi-poe-plus, fan control), which the firmware loads.

  # No LVFS firmware for a Pi.
  services.fwupd.enable = lib.mkForce false;
}
