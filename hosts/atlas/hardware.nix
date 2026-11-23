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

  # amd-pstate-epp active + powersave: EPP picks idle vs boost (xanmod's performance default pins
  # it). GameMode switches to performance during games.
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
    # sched_ext; `systemctl stop scx` falls back to EEVDF.
    scx = {
      enable = true;
      scheduler = "scx_lavd";
    };

    # Monthly scrub (once per filesystem despite many subvolume mounts).
    btrfs.autoScrub.enable = true;

    # Hourly /home snapshots into @snapshots (disks.nix).
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

  # Nested subvolumes stay out of /home snapshots: caches and omp sessions churn too much
  # (btrfs commits stalled up to 3.5s). `v` won't convert an existing plain directory.
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
