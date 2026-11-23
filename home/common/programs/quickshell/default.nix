{
  config,
  lib,
  pkgs,
  self,
  ...
}:

let
  theme = import "${self}/lib/theme" { inherit pkgs; };

  # The shell's helper programs: the scripts beside the QML, wrapped (scripts/default.nix).
  scripts = import ./scripts { inherit config lib pkgs; };

  # Instant replay (config/services/Replay.qml, the quickshell-replay unit below). The one place
  # that says how much is kept and of which screen. Kept in RAM at 20 Mbit/s (scripts/record.sh),
  # so every minute costs 150 MB: 300 s is 750 MB. The monitor is the gaming one (the 165 Hz
  # screen with VRR, workspace 1 at login; home/common/desktop/hyprland/config/monitors.nix).
  replaySeconds = 300;
  replayMonitor = "DP-1";
in
{
  programs.quickshell = {
    enable = true;
    configs = {
      bar = ./config;
      # Run by quickshell-wallpaper below, not by the module's service.
      wallpaper = ./wallpaper;
    };
    activeConfig = "bar";
    systemd.enable = true;
  };

  # The desktop wallpaper (wallpaper/shell.qml), in place of hyprpaper: its own instance so the
  # bar's restarts on switch never blank the desktop, restarted only when its own file changes.
  # set-wallpaper (home/common/programs/hypr/paper.nix) tells it about a new image over IPC.
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

  # The instant replay buffer (config/services/Replay.qml). A unit of its own, not a child of the
  # bar, so the bar's restarts on switch don't empty the buffer, and systemd restarts it if the
  # recorder dies (a driver reset, a resume from suspend). Not wanted by anything: the bar starts
  # it when replay is armed (state kept in its state dir) and the toggle stops it. SIGINT ends
  # the recorder cleanly; after five failures in five minutes the unit stays failed and the bar
  # turns replay off and says why.
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

  # The lighting engine (scripts/rgb.py serve): draws the look chosen in the Lighting section on
  # every OpenRGB device, LED by LED (only Direct mode reaches atlas's controllers), and again
  # whenever openrgb.service starts (boot, or the VFIO VM handing the devices back). Without a
  # server it waits and retries.
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

  # The config is a store symlink and fonts are only read at startup, so a running
  # instance never sees either change; restart it on switch instead.
  systemd.user.services.quickshell.Unit.X-Restart-Triggers = [
    "${./config}"
    "${theme.fonts.shell.package}"
    "${theme.fonts.iconFont.package}"
  ];

  systemd.user.services.quickshell.Service.Environment = [
    # Electron tray items (Discord) expose IconPixmap but no IconName, so every
    # icon update logs a harmless "Error updating property …IconName" warning (~1k per boot).
    "QT_LOGGING_RULES=quickshell.dbus.properties.warning=false"
    # wlsunset's location (home/common/programs/hypr/sunset.nix), for the bar's day arc.
    "QS_LATITUDE=${config.services.wlsunset.latitude}"
    "QS_LONGITUDE=${config.services.wlsunset.longitude}"
    # Where screen recordings go (xdg.userDirs, home/common/shell/xdg.nix).
    "QS_RECORDINGS_DIR=${config.xdg.userDirs.extraConfig.RECORDINGS}"
    # Instant replay (replaySeconds, replayMonitor above), for the capture menu's labels.
    "QS_REPLAY_SECONDS=${toString replaySeconds}"
    "QS_REPLAY_MONITOR=${replayMonitor}"
  ];

  home.packages = [
    # The shell's face and glyphs; installed here so they don't depend on the system font set.
    theme.fonts.shell.package
    theme.fonts.iconFont.package
    pkgs.iproute2
    # Holds the night light's session temperature (config/services/NightLight.qml).
    pkgs.hyprsunset
    # The Connections panel's Cast screen row (patched in overlays/default.nix).
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
