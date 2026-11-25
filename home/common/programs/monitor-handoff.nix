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
  # Input Source (VCP 0x60) value of the PC's port on the primary monitor.
  pcInput = "0f";

  monitorRule = mirror: lib.generators.toLua { multiline = false; } (primary // { inherit mirror; });

  # Workspaces bound to the primary (home/hosts/atlas.nix), returned to it on the switch back.
  primaryWorkspaces = lib.concatMapStringsSep ", " (r: r.workspace) (
    lib.filter (
      r: r.monitor == primary.output && builtins.match "[0-9]+" r.workspace != null
    ) config.wayland.windowManager.hyprland.settings.workspace_rule
  );

  monitorHandoff = pkgs.writeShellApplication {
    name = "monitor-handoff";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.ddcutil
      pkgs.gawk
      pkgs.jq
    ];
    # hyprctl from PATH matches the running compositor.
    text = ''
      primary=${lib.escapeShellArg primary.output}
      saved="''${XDG_RUNTIME_DIR:?}/monitor-handoff-workspace"

      # ddcutil lists the bus even while the monitor shows another input (and then exits non-zero).
      bus=$(ddcutil detect --brief 2>/dev/null | awk -v conn="-$primary" '
        /I2C bus:/ { bus = $3; sub("/dev/i2c-", "", bus) }
        /DRM connector:/ && substr($3, length($3) - length(conn) + 1) == conn { print bus; exit }
      ') || true
      if [ -z "$bus" ]; then
        echo "no DDC bus for $primary" >&2
        exit 1
      fi

      park() {
        # A config reload drops the mirror (hyprland.lua's rule has none); keep the first save.
        [ -s "$saved" ] || jq '.activeWorkspace.id' <<<"$1" >"$saved"
        hyprctl eval ${lib.escapeShellArg "hl.monitor(${monitorRule secondary.output})"} >/dev/null
        echo "$primary shows another input: mirroring it"
      }

      restore() {
        hyprctl eval ${lib.escapeShellArg "hl.monitor(${monitorRule ""})"} >/dev/null
        for _ in $(seq 25); do
          hyprctl -j monitors | jq -e --arg m "$primary" 'any(.[]; .name == $m)' >/dev/null && break
          sleep 0.2
        done
        hyprctl eval "
          for _, id in ipairs({ ${primaryWorkspaces} }) do
            if hl.get_workspace(id) then
              hl.dispatch(hl.dsp.workspace.move({ workspace = id, monitor = \"$primary\" }))
            end
          end
          local last = hl.get_workspace($(cat "$saved" 2>/dev/null || echo 0))
          if last then hl.dispatch(hl.dsp.focus({ workspace = last.id })) end
        " >/dev/null
        rm -f "$saved"
        echo "$primary shows the PC again: restored"
      }

      misses=0
      # DDC drops out for a few seconds after a modeset or DPMS wake; misses then don't count.
      settle_until=$((SECONDS + 10))
      last=$SECONDS
      while sleep 1; do
        # A suspend stops this loop, and DDC drops out after resume as after a DPMS wake.
        [ $((SECONDS - last)) -le 5 ] || settle_until=$((SECONDS + 30))
        last=$SECONDS

        # Plain `monitors` leaves out mirrors.
        monitor=$(hyprctl -j monitors all 2>/dev/null | jq -c --arg m "$primary" '.[] | select(.name == $m)') || monitor=
        if [ -z "$monitor" ] || [ "$(jq '.dpmsStatus' <<<"$monitor")" != true ]; then
          misses=0
          settle_until=$((SECONDS + 10))
          continue
        fi
        mirrored=$(jq '.mirrorOf != "none"' <<<"$monitor")

        # Defaults take ~0.3 s to answer and ~4 s to give up; short retries keep each poll quick.
        input=$(ddcutil --bus "$bus" --skip-ddc-checks --maxtries 2,2,2 getvcp 60 --brief 2>/dev/null |
          awk '$1 == "VCP" { print $4 }') || input=
        if [ "$input" = "x${pcInput}" ]; then
          misses=0
          if [ "$mirrored" = true ]; then
            restore
            settle_until=$((SECONDS + 10))
          else
            rm -f "$saved"
          fi
        elif [ "$mirrored" = false ] && [ "$SECONDS" -ge "$settle_until" ]; then
          misses=$((misses + 1))
          # A save means the mirror was dropped while away: re-park at once.
          if [ "$misses" -ge 3 ] || [ -s "$saved" ]; then
            park "$monitor"
            misses=0
          fi
        fi
      done
    '';
  };
in
{
  systemd.user.services.monitor-handoff = {
    Unit = {
      Description = "Move workspaces off ${primary.output} while it shows another input";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${monitorHandoff}" ];
    };
    Service = {
      ExecStart = lib.getExe monitorHandoff;
      Restart = "always";
      RestartSec = 10;
      Nice = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
