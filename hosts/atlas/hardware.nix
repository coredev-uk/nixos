{
  inputs,
  lib,
  meta,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disks.nix { inherit lib; })

    ../common/hardware/bluetooth.nix
    ../common/hardware/nvidia.nix
    ../common/hardware/razer.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware.cpu.amd.updateMicrocode = true;
  services.fstrim.enable = true;

  # amd-pstate-epp in active mode: powersave lets the energy-performance preference pick
  # between idle and boost (xanmod's default, performance, pins EPP to performance). GameMode
  # switches to performance while a game runs.
  boot.kernelParams = [ "amd_pstate=active" ];
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

  # Nested subvolumes are left out of the /home snapshots. Caches (Go's build cache alone
  # rewrote ~3 GB/h) and omp's agent sessions churned so much under hourly snapshots that
  # btrfs commits took up to 3.5s of CPU, stalling every fsync-ing app. `v` only creates a
  # subvolume where nothing exists yet; an existing plain directory needs moving by hand.
  systemd.tmpfiles.rules =
    let
      home = meta.homeDirectory;
      owner = "${meta.username} users";
    in
    [
      "d ${home}/.local 0755 ${owner} -"
      "v ${home}/.local/cache 0755 ${owner} -"
      "v ${home}/.omp 0755 ${owner} -"
    ];
}
