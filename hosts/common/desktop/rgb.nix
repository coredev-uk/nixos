_: {
  # Enable OpenRGB (the module adds its udev rules and loads i2c-dev)
  services.hardware.openrgb.enable = true;

  # /dev/i2c-* access for the i2c group
  hardware.i2c.enable = true;
}
