{ pkgs, lib, ... }:
let
  # hyprctl from PATH matches the running compositor. Lua config: dispatch takes a Lua dispatcher.
  dpms = action: "hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
  # Outputs in the layout only: a mirror keeps its signal (programs/monitor-handoff parks DP-1 as one).
  dpmsOffLayout = "hyprctl eval 'for _, m in ipairs(hl.get_monitors()) do hl.dispatch(hl.dsp.dpms({ action = \"disable\", monitor = m.name })) end'";
  loginctl = "${pkgs.systemd}/bin/loginctl";
  # Off/on: after an NVIDIA resume outputs can stay black while reporting DPMS on; only a cycle forces a modeset.
  # nvidia-sleep.sh parks the console on VT 63 across suspend and chvt's back only once nvidia-resume.service
  # finishes, seconds after logind's resume signal; commits before then fail ("Session inactive") and leave the
  # outputs dark while Hyprland believes DPMS is on. So wait for our session to be active again first.
  afterSleep = pkgs.writeShellScript "hypr-after-sleep" ''
    session=$(${loginctl} show-user "$(id -u)" -p Display --value)
    until [ "$(${loginctl} show-session "$session" -p Active --value)" = yes ]; do sleep 0.2; done
    sleep 1
    ${dpms "disable"}
    sleep 1
    ${dpms "enable"}
  '';
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
        after_sleep_cmd = "${afterSleep}";
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
          on-timeout = dpmsOffLayout;
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
