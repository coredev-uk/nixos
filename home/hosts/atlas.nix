{ lib, meta, ... }:
{
  # NZXT Kraken Elite in atlas.
  imports = [ ../common/programs/kraken-lcd ];

  # Primary screen takes workspaces 1-5, the second 6-10. Sunshine's headless STREAM output
  # (hosts/common/desktop/gaming.nix) opens on "tv", which comes back to it on the next stream.
  wayland.windowManager.hyprland.settings.workspace_rule =
    lib.genList (i: {
      workspace = toString (i + 1);
      monitor = (builtins.elemAt meta.monitors (if i < 5 then 0 else 1)).output;
      default = i == 0 || i == 5;
    }) 10
    ++ [
      {
        workspace = "name:tv";
        monitor = "STREAM";
        default = true;
      }
    ];
}
