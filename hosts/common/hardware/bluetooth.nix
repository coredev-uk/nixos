{ pkgs, meta, ... }:
{
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        KernelExperimental = true;
      };
    };
  };

  # Module (not just the package): also registers blueman's D-Bus mechanism and polkit
  # actions, which the applet/manager need for privileged actions.
  services.blueman.enable = meta.isDesktop;
}
