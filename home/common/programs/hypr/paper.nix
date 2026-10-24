{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Apple's names, from `macos-wallpaper list`: the dynamic landscapes, which follow the sun at
  # the location below. One is picked at random and kept; Super+Shift+P moves to another.
  pictures = [
    "The Lake"
    "The Desert"
    "The Beach"
    "The Cliffs"
    "Big Sur"
    "Catalina"
  ];

  # Not named after the source: hyprpaper and the lock screen read current.jpg from here
  # (home/common/programs/quickshell/default.nix).
  current = "${config.xdg.cacheHome}/wallpapers/current.jpg";

  macosWallpaper = inputs.macos-wallpapers.packages.${pkgs.stdenv.hostPlatform.system}.default;
  macosWallpaperArgs = [
    "--cache-dir"
    "${config.xdg.cacheHome}/macos-wallpapers"
    # The same place wlsunset uses (sunset.nix).
    "--latitude"
    config.services.wlsunset.latitude
    "--longitude"
    config.services.wlsunset.longitude
  ]
  ++ lib.concatMap (picture: [
    "--picture"
    picture
  ]) pictures;

  # set-wallpaper [current|next]: the image for now, or another picture's. Applies it only
  # when it changed, so the timer's runs are free most of the time.
  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper";
    runtimeInputs = [
      macosWallpaper
      pkgs.coreutils
      pkgs.util-linux
    ];
    # hyprctl comes from PATH so it always matches the running compositor.
    text = ''
      # The timer and the keybind can overlap.
      exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/set-wallpaper.lock"
      flock 9

      img=$(macos-wallpaper "''${1:-current}" ${lib.escapeShellArgs macosWallpaperArgs})
      [ "$(readlink ${lib.escapeShellArg current} || true)" = "$img" ] && exit 0

      # hyprpaper's config points here, so the next login starts on this image.
      mkdir -p "$(dirname ${lib.escapeShellArg current})"
      ln -sfn "$img" ${lib.escapeShellArg current}

      # The login screen shows it too; the greeter can't read this cache, so it gets a copy
      # (hosts/common/desktop/greeter.nix creates the directory).
      greeter=/var/lib/greeter-wallpaper
      if [ -w "$greeter" ]; then
        cp -f "$img" "$greeter/wallpaper.jpg.part" && mv -f "$greeter/wallpaper.jpg.part" "$greeter/wallpaper.jpg"
      fi

      for _ in $(seq 1 30); do
        hyprctl hyprpaper wallpaper ",$img, cover" && exit 0
        sleep 1
      done
      echo "hyprpaper did not accept $img" >&2
      exit 1
    '';
  };

  wallpaperService = description: command: {
    Unit = {
      Description = description;
      # Explicit After=graphical-session.target stops the target's implicit After= on this
      # unit (WantedBy), which formed a cycle with hyprpaper (After=graphical-session.target)
      # and stalled session startup for up to 30s whenever systemd dropped hyprpaper's job.
      After = [
        "graphical-session.target"
        "hyprpaper.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe setWallpaper} ${command}";
    };
  };
in
{
  services.hyprpaper = {
    enable = true;

    settings = {
      splash = false;

      # Shown as soon as hyprpaper starts, before macos-wallpaper.service has checked the sun.
      wallpaper = [
        {
          monitor = "";
          path = current;
          fit_mode = "cover";
        }
      ];
    };
  };

  systemd.user.services.macos-wallpaper =
    wallpaperService "Show the macOS wallpaper for the sun's position" "current"
    // {
      Install.WantedBy = [ "graphical-session.target" ];
    };

  # Started by Super+Shift+P (desktop/hyprland/config/keybindings.nix). Downloads the new picture
  # (65-140 MB) and renders the image for now, a few seconds; the old picture is removed.
  systemd.user.services.macos-wallpaper-next = wallpaperService "Switch to another macOS wallpaper" "next";

  # Dynamic pictures change with the sun; the images it can land between are an hour or more
  # apart, so ten minutes is close enough.
  systemd.user.timers.macos-wallpaper = {
    Unit = {
      Description = "Keep the macOS wallpaper in step with the sun";
      PartOf = [ "graphical-session.target" ];
    };
    Timer.OnCalendar = "*:0/10";
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
