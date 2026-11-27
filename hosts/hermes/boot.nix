{ lib, meta, ... }:
{
  imports = [
    ../common/base
    ../common/users/${meta.username}
  ];

  # Never bump (gates stateful migrations).
  system.stateVersion = "26.05";

  boot.loader = {
    # The Pi's firmware boots the kernel from /boot/firmware (hardware.nix); no EFI.
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    # nixos-raspberrypi's generational loader, which it recommends for new installs; keeps
    # previous generations bootable.
    raspberry-pi.bootloader = "kernel";
  };
}
