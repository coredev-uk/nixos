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

  # amd-pstate-epp in active mode: powersave lets the energy-performance preference pick
  # between idle and boost (xanmod's default, performance, pins EPP to performance). GameMode
  # switches to performance while a game runs.
  powerManagement.cpuFreqGovernor = "powersave";
  systemd.services.cpu-epp = {
    description = "Set the CPU energy-performance preference";
    after = [ "cpufreq.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        echo balance_performance > "$epp"
      done
    '';
  };

  services = {
    # sched_ext scheduler tuned for interactive and gaming latency; stopping the service
    # (`systemctl stop scx`) falls back to the kernel's EEVDF.
    scx = {
      enable = true;
      scheduler = "scx_lavd";
    };

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
