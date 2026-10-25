{
  self,
  lib,
  unstable,
  ...
}:
let
  # TODO: Remove when https://github.com/NixOS/nixpkgs/pull/576620 merged.
  # Audeze Maxwell 2 (3329:4b29) support starts in 4.0.0; 4.2.0 replaces the Maxwell
  # protocol (Sapd/HeadsetControl#591, tested on the Maxwell 2) and drops the init packet
  # that skewed the audio balance after battery reads (#577). nixpkgs is at 4.1.0.
  headsetcontrol = unstable.headsetcontrol.overrideAttrs (_: rec {
    version = "4.2.0";
    src = unstable.fetchFromGitHub {
      owner = "Sapd";
      repo = "HeadsetControl";
      rev = version;
      hash = "sha256-QwgH6w2CFRbH22Dc+MOdbtNZENbjf70XLhQ7D4DnhQc=";
    };
  });
in
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

  warnings = lib.optional (lib.versionAtLeast unstable.headsetcontrol.version "4.2.0") ''
    hosts/atlas/extra.nix: nixpkgs' headsetcontrol (${unstable.headsetcontrol.version}) has
    caught up with the 4.2.0 override; use unstable.headsetcontrol directly.
  '';

  # Battery readout for the quickshell panel (quickshell-batteries); the udev rules give
  # the logged-in user access to the headset's hidraw node.
  environment.systemPackages = [ headsetcontrol ];
  services.udev.packages = [ headsetcontrol ];

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
      comment = "Start the Windows 11 VM, or boot natively into Windows";
      icon = "vfio-windows-11";
      nativeBootEfiEntry = "Windows Boot Manager";
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
