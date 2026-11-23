# Hyprland monitors per host (meta.monitors, lib/helpers.nix); the greeter uses the same layout.
{
  atlas = [
    {
      output = "DP-1";
      mode = "2560x1440@165";
      position = "2560x0";
      scale = 1;
      cm = "srgb";
      # Always-on VRR (also covers tiled games, unlike misc:vrr 2/3).
      vrr = 1;
    }
    {
      output = "DP-2";
      mode = "2560x1440@144";
      position = "0x0";
      scale = 1;
      cm = "srgb";
    }
  ];

  default = [
    {
      output = "";
      mode = "preferred";
      position = "auto";
      scale = 1;
    }
  ];
}
