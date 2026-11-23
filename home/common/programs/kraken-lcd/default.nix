{
  lib,
  pkgs,
  theme,
  ...
}:
let
  # Kraken Elite screen as a CPU/GPU/coolant gauge via liquidctl's API. Device access: liquidctl udev
  # rules in hosts/common/desktop/rgb.nix.
  krakenLcd = pkgs.writers.writePython3Bin "kraken-lcd" {
    libraries = with pkgs.python3Packages; [
      liquidctl
      pillow
    ];
  } (builtins.readFile ./lcd.py);
in
{
  systemd.user.services.kraken-lcd = {
    Unit = {
      Description = "NZXT Kraken screen: CPU, GPU and coolant temperatures";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${krakenLcd}" ];
    };
    Service = {
      ExecStart = lib.getExe krakenLcd;
      Environment = [
        "KRAKEN_LCD_FONTS=${theme.fonts.shell.package}/share/fonts/opentype"
      ];
      Restart = "always";
      RestartSec = 10;
      Nice = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
