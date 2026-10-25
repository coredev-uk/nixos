{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Names from `macos-wallpaper list`: the dynamic landscapes, which follow the sun at the
  # location below. The first six are desktop pictures, the last three the macOS 15-27 places
  # made from Apple's aerial videos. The wallpaper picker (Super+Shift+P, quickshell's
  # WallpaperPicker) offers these; the one chosen stays until it's changed there.
  pictures = [
    "The Lake"
    "The Desert"
    "The Beach"
    "The Cliffs"
    "Big Sur"
    "Catalina"
    "Sequoia"
    "Tahoe"
    "Golden Gate"
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

  # set-wallpaper [current | set NAME]: the image for now of the picture in use, or of NAME
  # after switching to it. Applies it only when it changed, so the timer's runs are free most
  # of the time.
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

      if [ "$#" -eq 0 ]; then set -- current; fi
      img=$(macos-wallpaper "$@" ${lib.escapeShellArgs macosWallpaperArgs})
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

  # The picker's cards: every picture's low-res image for now, as JSON. The first call makes the
  # low-res copies (downloading each picture once); after that it's instant.
  wallpaperPreviews = pkgs.writeShellApplication {
    name = "wallpaper-previews";
    runtimeInputs = [ macosWallpaper ];
    text = ''
      exec macos-wallpaper previews ${lib.escapeShellArgs macosWallpaperArgs}
    '';
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

  # Called by name from quickshell's WallpaperPicker.
  home.packages = [
    setWallpaper
    wallpaperPreviews
  ];

  systemd.user.services.macos-wallpaper = {
    Unit = {
      Description = "Show the macOS wallpaper for the sun's position";
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
      ExecStart = "${lib.getExe setWallpaper} current";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Makes the picker's low-res copies of any picture that doesn't have them yet (a new name in
  # the list), so opening it doesn't wait; a no-op otherwise.
  systemd.user.services.wallpaper-previews = {
    Unit = {
      Description = "Make low-res previews of the macOS wallpapers";
      After = [
        "graphical-session.target"
        "macos-wallpaper.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe wallpaperPreviews;
      StandardOutput = "null";
      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

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
