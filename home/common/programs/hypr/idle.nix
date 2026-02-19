{ pkgs, lib, ... }:
{

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || ${lib.getExe pkgs.hyprlock}";
        before_sleep_cmd = "${pkgs.systemdUkify}/bin/loginctl lock-session";
        after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
        on_unlock_cmd = "set-brightness-all 100%";
      };

      listener = [
        {
          timeout = 150; # 2.5 minutes
          on-timeout = "set-brightness-all 10%";
          on-resume = "set-brightness-all 100%";
        }
        {
          timeout = 300; # 5 minutes
          on-timeout = "${pkgs.systemdUkify}/bin/loginctl lock-session";
        }
        {
          timeout = 330; # 5.5 minutes
          on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
          on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on && set-brightness-all 100%";
        }
        {
          timeout = 1800; # 30 minutes
          on-timeout = "${pkgs.systemdUkify}/bin/systemctl suspend";
        }
      ];
    };
  };

}
