{
  pkgs,
  meta,
  unstable,
  ...
}:
{
  imports = [
    ../common/services/networkmanager.nix
    ../common/services/printing.nix
    ../common/services/vfio.nix
    ../common/desktop/gaming.nix
    ../common/desktop/rgb.nix
    ../common/desktop/qmk.nix
    ../common/desktop/ddcci-driver.nix
    ../common/desktop/dev.nix
    ../common/base/nix-ld.nix
  ];

  boot.kernelParams = [
    # Split top-io USB controller for vfio passthrough
    "pcie_acs_override=downstream,multifunction"
    # SN770 root took ~12ms to wake from deep APST, stalling btrfs commits.
    "nvme_core.default_ps_max_latency_us=0"
  ];

  # Follows main each morning (or next boot if off). Main only gets changes after Hosts CI
  # cached atlas in Attic, so the switch just downloads. Local-checkout switches revert.
  system.autoUpgrade = {
    enable = true;
    flake = "github:coredev-uk/nixos#atlas";
    upgrade = false; # flakes, no channels
    dates = "05:00";
    randomizedDelaySec = "30min";
  };

  # Notify the user what changed (home/common/auto-upgrade); fails quietly if they're logged out,
  # and the next home upgrade reports it instead.
  systemd.services.nixos-upgrade.serviceConfig.ExecStopPost =
    "-${pkgs.writeShellScript "nixos-upgrade-report" ''
      ${pkgs.systemd}/bin/systemctl --user -M ${meta.username}@ --no-block \
        start "upgrade-report@system-$SERVICE_RESULT.service"
    ''}";

  # Headset battery for the quickshell panel; udev rules give the user hidraw access.
  environment.systemPackages = [ unstable.headsetcontrol ];
  services = {
    udev.packages = [ unstable.headsetcontrol ];

    vfioSingleGpu = {
      enable = true;
      vmName = "vfio-windows-11";
      iommu.cpuVendor = "amd";
      cancelRecoveryOnStarted = true;
      stopServices = [
        "greetd.service"
        "ddcci-nvidia-attach.service"
        "openrgb.service"
      ];
      restoreServices = [
        "greetd.service"
        "ddcci-nvidia-attach.service"
        "openrgb.service"
      ];
      # Also offered in the shell's power menu.
      nativeBootEfiEntry = "Windows Boot Manager";
    };

    # No suspend on the Toslink output (audio popping).
    pipewire.wireplumber.extraConfig."99-disable-suspend" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "node.name" = "alsa_output.usb-Generic_ATH-M50xSTS-USB-00.analog-stereo";
            }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };

  };
}
