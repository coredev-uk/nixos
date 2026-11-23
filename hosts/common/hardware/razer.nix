{ meta, ... }:
{
  # Daemon only; the bar reads peripheral batteries over D-Bus.
  hardware.openrazer = {
    enable = true;
    batteryNotifier = {
      enable = true;
      percentage = 20;
    };
    users = [ meta.username ];
  };
}
