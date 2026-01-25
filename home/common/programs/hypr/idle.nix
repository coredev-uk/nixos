{ pkgs, lib, ... }:
let
  set-brightness-all = pkgs.writeScriptBin "set-brightness-all" ''
    # Usage: set-brightness-all +10%  OR  set-brightness-all 50%
    VAL=$1

    # Find all ddcci devices in /sys/class/backlight
    # We run them in the background (&) so they update simultaneously/instantly
    for dev in $(ls /sys/class/backlight/ | grep ddcci); do
      if ["$VAL" == "restore"]; then 
        ${pkgs.brightnessctl}/bin/brightnessctl -r &
      else
        ${pkgs.brightnessctl}/bin/brightnessctl -d "$dev" set "$VAL" &
      fi
    done

    # Wait for both to finish before exiting
    wait
  '';

in
{

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || ${lib.getExe pkgs.hyprlock}";
        before_sleep_cmd = "${pkgs.systemdUkify}/bin/loginctl lock-session";
        after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 150; # 2.5 minutes
          on-timeout = "${set-brightness-all}/bin/set-brightness-all 10%";
          on-resume = "${set-brightness-all}/bin/set-brightness-all restore";
        }
        {
          timeout = 300; # 5 minutes
          on-timeout = "${pkgs.systemdUkify}/bin/loginctl lock-session";
        }
        {
          timeout = 330; # 5.5 minutes
          on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on && ${set-brightness-all}/bin/set-brightness-all restore";
        }
        {
          timeout = 1800; # 30 minutes
          on-timeout = "${pkgs.systemdUkify}/bin/systemctl suspend";
        }
      ];
    };
  };

}
