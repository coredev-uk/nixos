{ lib, meta, ... }:
{
  # NZXT Kraken Elite in atlas.
  imports = [ ../common/programs/kraken-lcd ];

  # Primary screen takes workspaces 1-5, the second 6-10.
  wayland.windowManager.hyprland.settings.workspace_rule = lib.genList (i: {
    workspace = toString (i + 1);
    monitor = (builtins.elemAt meta.monitors (if i < 5 then 0 else 1)).output;
    default = i == 0 || i == 5;
  }) 10;
}
