{
  config,
  lib,
  pkgs,
  meta,
  ...
}:
let
  # The primary monitor is shared with a laptop: while it shows another input, its workspaces move
  # to the second screen. Hotplug can't tell (the DP link stays up), but DDC/CI answers on the PC's
  # link only while the monitor shows it. Away, the output mirrors the second: out of the layout,
  # but still sending a signal, without which Auto Input Switch bounces a switch back to the laptop.
  primary = builtins.elemAt meta.monitors 0;
  secondary = builtins.elemAt meta.monitors 1;

  monitorRule = mirror: lib.generators.toLua { multiline = false; } (primary // { inherit mirror; });

  settings = pkgs.writeText "monitor-handoff.json" (
    builtins.toJSON {
      inherit (primary) output;
      # Input Source (VCP 0x60) value of the PC's port on the primary monitor.
      pcInput = 15;
      park = "hl.monitor(${monitorRule secondary.output})";
      restore = "hl.monitor(${monitorRule ""})";
      # Workspaces bound to the primary (home/hosts/atlas.nix), returned to it on the switch back.
      workspaces = map (r: lib.toInt r.workspace) (
        lib.filter (
          r: r.monitor == primary.output && builtins.match "[0-9]+" r.workspace != null
        ) config.wayland.windowManager.hyprland.settings.workspace_rule
      );
      ddcutil = lib.getExe pkgs.ddcutil;
    }
  );

  # hyprctl from PATH matches the running compositor.
  monitorHandoff = pkgs.writers.writePython3Bin "monitor-handoff" { } (
    builtins.readFile ./handoff.py
  );
in
{
  systemd.user.services.monitor-handoff = {
    Unit = {
      Description = "Move workspaces off ${primary.output} while it shows another input";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [
        "${monitorHandoff}"
        "${settings}"
      ];
    };
    Service = {
      ExecStart = "${lib.getExe monitorHandoff} ${settings}";
      Restart = "always";
      RestartSec = 10;
      Nice = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
