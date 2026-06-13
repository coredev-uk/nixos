{
  self,
  pkgs,
  ...
}:
let
  bootwin = pkgs.writeScriptBin "bootwin" ''
    #!/bin/sh
    sudo su - <<EOF
    efibootmgr -n 0000
    reboot
    EOF
  '';
in
{
  imports = [
    "${self}/hosts/common/services/networkmanager.nix"
    "${self}/hosts/common/services/vfio.nix"
    "${self}/hosts/common/desktop/1password.nix"
    "${self}/hosts/common/desktop/gaming.nix"
    "${self}/hosts/common/desktop/rgb.nix"
    "${self}/hosts/common/desktop/qmk.nix"
    "${self}/hosts/common/desktop/ddcci-driver.nix"
    "${self}/hosts/common/desktop/dev.nix"
    "${self}/hosts/common/base/nix-ld.nix"
  ];

  # Add bootwin script to reboot into Windows
  environment.systemPackages = [
    bootwin
    pkgs.headsetcontrol
  ];

  services.vfioSingleGpu = {
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
    desktopItem = {
      name = "windows";
      desktopName = "Windows";
      comment = "Start the Windows 11 VM with single-GPU passthrough";
      icon = "vfio-windows-11";
    };
  };

  # Split top-io usb controller for vfio passthrough
  boot.kernelParams = [
    "pcie_acs_override=downstream,multifunction"
  ];

  # Disable suspend of Toslink output to prevent audio popping.
  services.pipewire.wireplumber.extraConfig."99-disable-suspend" = {
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
}
