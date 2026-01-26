_: {
  hardware.nvidia = {
    # Force use the proprietary Nvidia drivers
    open = false;

    # Required for proper refresh rate handling afaik
    forceFullCompositionPipeline = true;

    # Wayland
    modesetting.enable = true;

    powerManagement = {
      enable = true;
      finegrained = false;
    };

    nvidiaSettings = true;
  };

}
