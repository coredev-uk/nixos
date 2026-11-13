{ unstable, ... }:
{
  # Enable OpenRGB (the module adds its udev rules and loads i2c-dev).
  # From unstable: 26.05 ships 1.0rc3.
  services.hardware.openrgb = {
    enable = true;
    package = unstable.openrgb;
  };

  # /dev/i2c-* access for the i2c group
  hardware.i2c.enable = true;

  # The NZXT Kraken Elite (1e71:300c), which OpenRGB doesn't know: its LCD and the RGB port on
  # the pump go through liquidctl. Its rules give the logged-in user the USB device itself, which
  # the LCD's image uploads need (bulk transfers, not hidraw).
  environment.systemPackages = [ unstable.liquidctl ];
  services.udev.packages = [ unstable.liquidctl ];
}
