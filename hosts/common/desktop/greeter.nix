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

  # The same QML tree as the bar and lock screen (home/common/programs/quickshell); the greeter
  # reuses the lock screen's faces.
  quickshellConfig = ../../../home/common/programs/quickshell/config;

  # set-wallpaper (home/common/programs/hypr/paper.nix) copies each new wallpaper here: the greeter
  # runs as `greeter` and can't read the cache in the user's home.
  wallpaperDir = "/var/lib/greeter-wallpaper";

  monitors =
    let
      all = import ../../../home/common/desktop/hyprland/config/monitors.nix { };
    in
    all.${meta.hostname} or all.default;

  # What greetd starts once the password is accepted: the package's hyprland-uwsm.desktop
  # launch line. uwsm runs hyprland.desktop (start-hyprland -> /run/wrappers/bin/Hyprland) and
  # exports the session environment, including ~/.config/uwsm/env, into the systemd user manager.
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

  # Runs the greeter UI, then closes the compositor: greetd starts the session only once the greeter
  # exits. Also the way out if quickshell fails, so greetd starts a fresh greeter.
  greeterShell = pkgs.writeShellScript "quickshell-greeter" ''
    export QS_GREETER_USER=${lib.escapeShellArg meta.username}
    export QS_GREETER_SESSION=${lib.escapeShellArg (builtins.toJSON session)}
    export QS_LOCK_WALLPAPER=${wallpaperDir}/wallpaper.jpg
    ${lib.getExe unstable.quickshell} --path ${quickshellConfig}/greeter.qml
    ${hyprland}/bin/hyprctl dispatch 'hl.dsp.exit()'
  '';

  # Greeter-only Hyprland: the session's monitor layout and keyboard layout (the password is typed
  # here), nothing else.
  greeterConfig = pkgs.writeText "greeter-hyprland.lua" ''
    ${lib.concatMapStrings (monitor: "hl.monitor(${toLua monitor})\n") monitors}
    hl.config(${
      toLua {
        # Must match home/common/desktop/hyprland/default.nix.
        input.kb_layout = "gb";
        animations.enabled = false;
        # Its data dir is new every boot, so these would pop up over the login screen.
        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          # Launched directly rather than through start-hyprland's watchdog.
          disable_watchdog_warning = true;
          force_default_wallpaper = 0;
          # Shown for the moment before the greeter's first frame.
          background_color = "rgb(${lib.removePrefix "#" theme.colours.crust})";
        };
      }
    })
    hl.on("hyprland.start", function()
      hl.exec_cmd("${greeterShell}")
    end)
  '';

  greeterSession = pkgs.writeShellScript "greeter-hyprland" ''
    # The greeter user's home is /var/empty: keep caches and state in its runtime dir.
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
  # If the greeter can't start, log in on another TTY (Ctrl+Alt+F2).
  services.greetd.settings.default_session.command = "${greeterSession}";

  systemd.tmpfiles.rules = [ "d ${wallpaperDir} 0755 ${meta.username} users -" ];
}
