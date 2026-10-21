{ config, ... }: {
  hardware.nvidia = {
    # Force use the proprietary Nvidia drivers
    open = false;

    # TODO: remove when https://github.com/NixOS/nixpkgs/issues/554125 fixed
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "610.57.04";
      sha256_64bit = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
      sha256_aarch64 = "sha256-QCefrMBCmpOwuOyXv1k5Gj0iB2CYlPgnG3JToUw/j54=";
      openSha256 = "sha256-rQHOOOY4KL92Ww3KDwh+j4eGU7oNAH8LutZC5wmFnPo=";
      settingsSha256 = "sha256-ZEMo8I8Zc2Tq6RVDNYpAH+f094dUaZiBqO+5f6lIjRI=";
      persistencedSha256 = "sha256-aXmD2VY1RLlgAnlHhOUMWzvMyhI6JTClcFLm4imF/mA=";
    };

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
