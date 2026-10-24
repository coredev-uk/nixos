{ pkgs, lib, ... }:
let
  # hyprctl from PATH matches the running compositor (NixOS programs.hyprland.package).
  # With a Lua config, `hyprctl dispatch` evaluates `hl.dispatch(<arg>)`, so pass a Lua dispatcher.
  dpms = action: "hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
in
{
  # Holds a Wayland idle inhibitor (respected by hypridle) while PipeWire is playing audio.
  systemd.user.services.wayland-pipewire-idle-inhibit = {
    Unit = {
      Description = "Inhibit idle while audio is playing";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      ExecStart = "${lib.getExe pkgs.wayland-pipewire-idle-inhibit}";
      Restart = "on-failure";
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # home/common/programs/quickshell/default.nix; exits at once if a lock is already up.
        lock_cmd = "quickshell-lock";
        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
        after_sleep_cmd = dpms "enable";
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
          on-timeout = "${pkgs.systemd}/bin/loginctl lock-session";
        }
        {
          timeout = 330; # 5.5 minutes
          on-timeout = dpms "disable";
          on-resume = "${dpms "enable"} && set-brightness-all 100%";
        }
        {
          timeout = 1800; # 30 minutes
          on-timeout = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
    };
  };

}
