{
  config,
  lib,
  pkgs,
  self,
  meta,
  unstable,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  hyprland = config.programs.hyprland.package;
  toLua = lib.generators.toLua { };

  # Same QML tree as the bar and lock screen.
  quickshellConfig = ../../../home/common/programs/quickshell/config;

  # set-wallpaper/wallpaper-video (hypr/paper.nix) copy wallpapers here: `greeter` can't read the
  # user's cache.
  wallpaperDir = "/var/lib/greeter-wallpaper";

  # Qt Multimedia + VA-API for the clip, as the lock's (video.nix); unstable to match the
  # greeter's quickshell and its patched Qt.
  video = import ../../../home/common/programs/quickshell/video.nix { pkgs = unstable; };

  monitors =
    let
      all = import ../../../home/common/desktop/hyprland/config/monitors.nix { };
    in
    all.${meta.hostname} or all.default;

  # wlsunset location (hypr/sunset.nix) for the next sunrise/sunset; the greeter can't see the
  # home-manager config, so the module is read directly.
  location = (import ../../../home/common/programs/hypr/sunset.nix { }).services.wlsunset;

  # greetd's launch line, from the package's hyprland-uwsm.desktop; uwsm exports the session
  # environment (incl. ~/.config/uwsm/env) into the systemd user manager.
  session = {
    command = [
      (lib.getExe config.programs.uwsm.package)
      "start"
      "-e"
      "-D"
      "Hyprland"
      "hyprland.desktop"
    ];
    environment = [ "GTK_THEME=${theme.gtkTheme.name}" ];
  };

  # Runs the greeter UI, then exits the compositor: greetd starts the session only after the
  # greeter exits, which is also the recovery if quickshell fails.
  greeterShell = pkgs.writeShellScript "quickshell-greeter" ''
    export QS_GREETER_USER=${lib.escapeShellArg meta.username}
    export QS_GREETER_SESSION=${lib.escapeShellArg (builtins.toJSON session)}
    export QS_LOCK_WALLPAPER=${wallpaperDir}/wallpaper.jpg
    export QS_LATITUDE=${lib.escapeShellArg location.latitude}
    export QS_LONGITUDE=${lib.escapeShellArg location.longitude}
    greeter() {
      ${lib.getExe unstable.quickshell} --path ${quickshellConfig}/greeter.qml
    }
    # Wallpaper clip if present (copied by set-wallpaper/wallpaper-video); else the still, without
    # loading Qt Multimedia. If the greeter dies with the clip, retry with the still alone.
    if [ -s ${wallpaperDir}/wallpaper.mp4 ]; then
      (
        export QS_LOCK_VIDEO=${wallpaperDir}/wallpaper.mp4
        # The lock's session sets this; the greeter has no such profile.
        export LIBVA_DRIVER_NAME=nvidia
        ${video.environment}
        greeter
      ) || greeter
    else
      greeter
    fi
    ${hyprland}/bin/hyprctl dispatch 'hl.dsp.exit()'
  '';

  # Greeter-only Hyprland: monitor and keyboard layout only.
  greeterConfig = pkgs.writeText "greeter-hyprland.lua" ''
    ${lib.concatMapStrings (monitor: "hl.monitor(${toLua monitor})\n") monitors}
    hl.config(${
      toLua {
        # Must match home/common/desktop/hyprland/default.nix.
        input.kb_layout = "gb";
        animations.enabled = false;
        # New data dir every boot: these would pop up over the login screen.
        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          # Not started through start-hyprland's watchdog.
          disable_watchdog_warning = true;
          force_default_wallpaper = 0;
          # Before the greeter's first frame.
          background_color = "rgb(${lib.removePrefix "#" theme.meridian.ground})";
        };
      }
    })
    hl.on("hyprland.start", function()
      hl.exec_cmd("${greeterShell}")
    end)
  '';

  greeterSession = pkgs.writeShellScript "greeter-hyprland" ''
    # Home is /var/empty: keep caches/state in the runtime dir.
    export XDG_CACHE_HOME="$XDG_RUNTIME_DIR/cache"
    export XDG_CONFIG_HOME="$XDG_RUNTIME_DIR/config"
    export XDG_DATA_HOME="$XDG_RUNTIME_DIR/data"
    export XDG_STATE_HOME="$XDG_RUNTIME_DIR/state"
    export XCURSOR_PATH=${theme.cursorTheme.package}/share/icons
    export XCURSOR_THEME=${theme.cursorTheme.name}
    export XCURSOR_SIZE=${toString theme.cursorTheme.size}
    exec ${hyprland}/bin/Hyprland --config ${greeterConfig}
  '';
in
{
  # Greeter broken: log in on another TTY (Ctrl+Alt+F2).
  services.greetd.settings.default_session.command = "${greeterSession}";

  # No home-manager profile for `greeter`: the shell font comes from the system set. The session
  # (shell, Hyprland group tabs, Vicinae) uses it too.
  fonts.packages = [ theme.fonts.shell.package ];

  systemd.tmpfiles.rules = [ "d ${wallpaperDir} 0755 ${meta.username} users -" ];
}
