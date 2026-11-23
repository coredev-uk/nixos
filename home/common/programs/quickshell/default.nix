{
  config,
  lib,
  pkgs,
  self,
  ...
}:

let
  theme = import "${self}/lib/theme" { inherit pkgs; };

  scripts = import ./scripts { inherit config lib pkgs; };

  # Replay buffer lives in RAM at 20 Mbit/s (record.sh): 300 s ≈ 750 MB.
  # DP-1 is the 165 Hz VRR gaming monitor.
  replaySeconds = 300;
  replayMonitor = "DP-1";
in
{
  programs.quickshell = {
    enable = true;
    configs = {
      bar = ./config;
      wallpaper = ./wallpaper;
    };
    activeConfig = "bar";
    systemd.enable = true;
  };

  # Own instance so bar restarts never blank the desktop. set-wallpaper (hypr/paper.nix) signals it over IPC.
  systemd.user.services.quickshell-wallpaper = {
    Unit = {
      Description = "Desktop wallpaper (Quickshell)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${./wallpaper}" ];
    };
    Service = {
      ExecStart = "${lib.getExe config.programs.quickshell.package} --config wallpaper";
      Environment = [
        "QS_WALLPAPER=${config.xdg.cacheHome}/wallpapers/current.jpg"
      ];
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Own unit, not a bar child: bar restarts on switch must not empty the buffer. Started/stopped
  # by the bar (not wanted by anything); SIGINT ends the recorder cleanly; after 5 failures in
  # 5 min it stays failed and the bar turns replay off.
  systemd.user.services.quickshell-replay = {
    Unit = {
      Description = "Instant replay buffer (Quickshell)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      StartLimitIntervalSec = 300;
      StartLimitBurst = 5;
    };
    Service = {
      ExecStart = "${lib.getExe scripts.record} --replay ${replayMonitor} ${config.xdg.userDirs.extraConfig.RECORDINGS} ${toString replaySeconds}";
      KillSignal = "SIGINT";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Lighting engine (scripts/rgb.py serve): redraws on every openrgb.service start (boot, VFIO VM
  # handback); only Direct mode reaches atlas's controllers.
  systemd.user.services.quickshell-rgb = {
    Unit = {
      Description = "Lighting engine for OpenRGB (Quickshell)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${scripts.rgb}" ];
    };
    Service = {
      ExecStart = "${lib.getExe scripts.rgb} serve";
      Restart = "always";
      RestartSec = 5;
      Nice = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Config is a store symlink and fonts load at startup: restart on change.
  systemd.user.services.quickshell.Unit.X-Restart-Triggers = [
    "${./config}"
    "${theme.fonts.shell.package}"
    "${theme.fonts.iconFont.package}"
  ];

  systemd.user.services.quickshell.Service.Environment = [
    # Electron tray items (Discord) have IconPixmap but no IconName: silences the warning per update.
    "QT_LOGGING_RULES=quickshell.dbus.properties.warning=false"
    # For the bar's day arc.
    "QS_LATITUDE=${config.services.wlsunset.latitude}"
    "QS_LONGITUDE=${config.services.wlsunset.longitude}"
    # xdg.userDirs RECORDINGS
    "QS_RECORDINGS_DIR=${config.xdg.userDirs.extraConfig.RECORDINGS}"
    # For the capture menu's labels.
    "QS_REPLAY_SECONDS=${toString replaySeconds}"
    "QS_REPLAY_MONITOR=${replayMonitor}"
  ];

  home.packages = [
    # Installed here so they don't depend on the system font set.
    theme.fonts.shell.package
    theme.fonts.iconFont.package
    pkgs.iproute2
    # Holds the night light's session temperature.
    pkgs.hyprsunset
    # Cast screen row (patched in overlays/default.nix).
    pkgs.gnome-network-displays
    scripts.vpn
    scripts.batteries
    scripts.rgb
    scripts.nixStatus
    scripts.claudeUsage
    scripts.lock
    scripts.pass
    scripts.calendar
    scripts.screenshot
    scripts.record
  ];

  # Read when xdph starts: restart xdg-desktop-portal-hyprland after a change.
  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      custom_picker_binary = ${scripts.sharePicker}/bin/quickshell-share-picker
    }
  '';
}
