{ pkgs, lib, ... }:
let
  # hyprctl from PATH matches the running compositor. Lua config: dispatch takes a Lua dispatcher.
  dpms = action: "hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
in
{
  # Idle inhibitor (honoured by hypridle) while PipeWire plays audio.
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
        # quickshell/scripts/default.nix; no-op if already locked.
        lock_cmd = "quickshell-lock";
        # Delay suspend until locked (logind inhibit).
        inhibit_sleep = 3;
        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
        # Off/on: after an NVIDIA resume outputs can stay black while reporting DPMS on; only a cycle forces a modeset.
        after_sleep_cmd = "${dpms "disable"}; sleep 1; ${dpms "enable"}";
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
          # Via logind like the other locks; input within 10 s resumes without password.
          on-timeout = "quickshell-lock --grace 10";
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
