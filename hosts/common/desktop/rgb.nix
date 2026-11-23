{ unstable, ... }:
{
  # Unstable: 26.05 ships 1.0rc3.
  services.hardware.openrgb = {
    enable = true;
    package = unstable.openrgb;
  };

  # /dev/i2c-* for the i2c group
  hardware.i2c.enable = true;

  # NZXT Kraken Elite (1e71:300c), unknown to OpenRGB: LCD and pump RGB go through liquidctl;
  # its udev rules give the user the USB device (LCD uploads use bulk transfers, not hidraw).
  environment.systemPackages = [ unstable.liquidctl ];
  services.udev.packages = [ unstable.liquidctl ];
}
