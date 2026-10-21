{
  config,
  lib,
  pkgs,
  ...
}:

{

  config = lib.mkIf config.hardware.nvidia.enabled {
    boot.extraModulePackages = with config.boot.kernelPackages; [ ddcci-driver ];
    boot.kernelModules = [
      "i2c-dev"
      "ddcci_backlight"
    ];

    boot.extraModprobeConfig = ''
      options nvidia NVreg_RegistryDwords="RMUseSwI2c=0x01; RMI2cSpeed=100"
    '';

    # 3. Auto-Attach Service
    systemd.services.ddcci-nvidia-attach = {
      description = "Attach ddcci driver to all Nvidia I2C buses";
      after = [ "greetd.service" ];
      requires = [ "greetd.service" ];
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
        ExecStart =
          let
            ddcciSetupScript = pkgs.writeShellScript "ddcci-setup" ''
              for i2c_path in /sys/bus/i2c/devices/i2c-*; do
                if [ -e "$i2c_path/name" ]; then
                  if ${pkgs.gnugrep}/bin/grep -q "NVIDIA" "$i2c_path/name"; then
                    bus=''${i2c_path##*/i2c-}
                    device="$i2c_path/''${bus}-0037"

                    if [ -e "$device" ]; then
                      echo "ddcci already attached at $device."
                      continue
                    fi

                    echo "Detected Nvidia I2C bus at $i2c_path."
                    echo ddcci 0x37 > "$i2c_path/new_device"
                    sleep 1
                  fi
                fi
              done            
            '';
          in
          "${ddcciSetupScript}";
      };
    };
  };

}
