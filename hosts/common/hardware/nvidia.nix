{ config, lib, ... }:
let
  inherit (config.boot.kernelPackages) nvidiaPackages;

  # Pinned: nixpkgs' stable driver doesn't build on Linux 7.2: https://github.com/NixOS/nixpkgs/issues/554125
  pinned = nvidiaPackages.mkDriver {
    version = "610.57.04";
    sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
    # Needed even with open = false: the GSP firmware comes from it.
    openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
    settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
    persistencedSha256 = "sha256-aXmD2VY1RLlgAnlHhOUMWzvMyhI6JTClcFLm4imF/mA=";
  };
in
{
  # Fixed in the 610 branch, which nixpkgs carries as `latest` (`stable` is on 595).
  warnings = lib.optional (lib.versionAtLeast nvidiaPackages.latest.version pinned.version) ''
    hosts/common/hardware/nvidia.nix: nixpkgs' latest NVIDIA driver (${nvidiaPackages.latest.version})
    has caught up with the pinned ${pinned.version}. Check NixOS/nixpkgs#554125 and drop the pin.
  '';

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Proprietary modules: the open ones broke the single-GPU VM (card stayed black, fans full),
    # lock up Ampere + Hyprland (open-gpu-kernel-modules#1411) and fail VFIO ROM reads (#955).
    open = false;

    package = pinned;

    # PAT instead of MTRR for write-combined mappings.
    moduleParams.nvidia.NVreg_UsePageAttributeTable = 1;

    modesetting.enable = true;

    powerManagement.enable = true;

    nvidiaSettings = true;
  };

}
