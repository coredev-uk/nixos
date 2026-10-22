{ config, lib, ... }:
let
  inherit (config.boot.kernelPackages) nvidiaPackages;

  # Pinned because nixpkgs' stable driver fails to build against Linux 7.2
  # (xanmod_latest): https://github.com/NixOS/nixpkgs/issues/554125
  pinned = nvidiaPackages.mkDriver {
    version = "610.57.04";
    sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
    # Also needed with open = false: the GSP firmware is extracted from it.
    openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
    settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
    persistencedSha256 = "sha256-aXmD2VY1RLlgAnlHhOUMWzvMyhI6JTClcFLm4imF/mA=";
  };
in
{
  warnings = lib.optional (lib.versionAtLeast nvidiaPackages.stable.version pinned.version) ''
    hosts/common/hardware/nvidia.nix: nixpkgs' stable NVIDIA driver (${nvidiaPackages.stable.version})
    has caught up with the pinned ${pinned.version}. Check NixOS/nixpkgs#554125 and drop the pin.
  '';

  hardware.nvidia = {
    # Force use the proprietary Nvidia drivers
    open = false;

    package = pinned;

    # Required for proper refresh rate handling afaik
    # forceFullCompositionPipeline = true;

    # Wayland
    modesetting.enable = true;

    powerManagement = {
      enable = true;
      finegrained = false;
    };

    nvidiaSettings = true;
  };

}
