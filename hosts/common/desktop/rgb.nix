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
}
