{ meta, ... }:
{
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Experimental = true;
        KernelExperimental = true;
      };
    };
  };

  # Module, not just the package: registers blueman's D-Bus mechanism and polkit actions.
  services.blueman.enable = meta.isDesktop;
}
