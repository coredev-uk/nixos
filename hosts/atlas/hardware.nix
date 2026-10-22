{ inputs, lib, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disks.nix { inherit lib; })

    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    # inputs.nixos-hardware.nixosModules.common-hidpi
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    ../common/hardware/bluetooth.nix
    ../common/hardware/nvidia.nix
    ../common/hardware/razer.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  services = {
    # Monthly checksum verification; the default list is de-duplicated per device, so the
    # single LUKS/btrfs filesystem is scrubbed once despite its many subvolume mounts.
    btrfs.autoScrub.enable = true;

    # Hourly snapshots of /home into the @snapshots subvolume (disks.nix). No `volume`
    # section, so paths are absolute; both live on the same btrfs filesystem.
    btrbk.instances.btrbk = {
      onCalendar = "hourly";
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "2d";
        snapshot_preserve = "48h 14d 4w";
        snapshot_dir = "/.snapshots";
        subvolume."/home" = { };
      };
    };
  };
}
