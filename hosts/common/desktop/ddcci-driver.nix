{
  config,
  lib,
  ...
}:

{

  boot.extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];
  boot.kernelModules = [
    "i2c-dev"
    "ddcci_backlight"
  ];

  config = lib.mkIf config.hardware.nvidia.enabled {
    boot.extraModprobeConfig = ''
      options nvidia NVreg_RegistryDwords="RMUseSwI2c=0x01; RMI2cSpeed=100"
    '';

    # 3. Auto-Attach Service
    systemd.services.ddcci-nvidia-attach = {
      description = "Attach ddcci driver to all Nvidia I2C buses";
      after = [ "graphical.target" ];
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        Type = "oneshot";
        script = ''
          for i2c_path in /sys/bus/i2c/devices/i2c-*; do
            if [ -e "$i2c_path/name" ]; then
              if grep -q "NVIDIA" "$i2c_path/name"; then
                echo "Detected Nvidia I2C bus at $i2c_path. Attempting to attach ddcci..."
                echo ddcci 0x37 > "$i2c_path/new_device" || true
              fi
            fi
          done
        '';
      };
    };
  };

}
