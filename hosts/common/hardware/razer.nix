{ meta, ... }:
{
  # The daemon alone: the bar reads peripheral batteries from it over D-Bus
  # (home/common/programs/quickshell/scripts/batteries.sh).
  hardware.openrazer = {
    enable = true;
    batteryNotifier = {
      enable = true;
      percentage = 20;
    };
    users = [ meta.username ];
  };
}
