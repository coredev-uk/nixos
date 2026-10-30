{
  self,
  unstable,
  ...
}:
{
  imports = [
    "${self}/hosts/common/services/networkmanager.nix"
    "${self}/hosts/common/services/printing.nix"
    "${self}/hosts/common/services/vfio.nix"
    "${self}/hosts/common/desktop/1password.nix"
    "${self}/hosts/common/desktop/gaming.nix"
    "${self}/hosts/common/desktop/rgb.nix"
    "${self}/hosts/common/desktop/qmk.nix"
    "${self}/hosts/common/desktop/ddcci-driver.nix"
    "${self}/hosts/common/desktop/dev.nix"
    "${self}/hosts/common/base/nix-ld.nix"
  ];

  # Split top-io usb controller for vfio passthrough
  boot.kernelParams = [
    "pcie_acs_override=downstream,multifunction"
  ];

  # Battery readout for the quickshell panel (quickshell-batteries); the udev rules give
  # the logged-in user access to the headset's hidraw node.
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
      # Offered in the shell's power menu, as is starting the VM.
      nativeBootEfiEntry = "Windows Boot Manager";
    };

    # Disable suspend of Toslink output to prevent audio popping.
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
