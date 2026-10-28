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
      pkgs.systemd
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

      # The lock screen's clip of the old image no longer matches; wallpaper-video makes or
      # finds the new one in the background.
      rm -f ${lib.escapeShellArg currentVideo}
      systemctl --user start --no-block wallpaper-video.service

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

  # sylvan.apple.com, which serves the aerial videos, chains to Apple's own root CA rather than
  # one in the system bundle; pinned by hash, as macos-wallpapers does (it doesn't export its copy).
  appleRootCa =
    pkgs.runCommand "apple-root-ca.pem"
      {
        nativeBuildInputs = [ pkgs.openssl ];
        der = pkgs.fetchurl {
          url = "https://www.apple.com/appleca/AppleIncRootCertificate.cer";
          hash = "sha256-sLFzDsvH/0UFFCxJ8Slebtpryu1+LGjFvpG1oRAB8CQ=";
        };
      }
      ''
        openssl x509 -inform der -in "$der" -out "$out"
      '';

  # The lock screen's moving background (home/common/programs/quickshell/config/lock/LockVideo.qml):
  # the aerial video the current image is the first frame of, as current.mp4 next to current.jpg.
  # Apple ships each as 4K HEVC at 240 fps, more than any screen here shows and enough to
  # saturate the GPU's decoder on two screens; it's made once per image at the largest screen's
  # size and the fastest rate Apple's frames divide into evenly within the fastest screen's
  # refresh (240 / 2^k: 120 for a 144-165 Hz screen), 10-bit like the source. Clips of the
  # current picture are kept, so the sun's next change finds its clip ready; pictures that
  # aren't aerial videos (the HEIC landscapes) have none.
  currentVideo = "${config.xdg.cacheHome}/wallpapers/current.mp4";
  wallpaperVideo = pkgs.writeShellApplication {
    name = "wallpaper-video";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.ffmpeg-headless
      pkgs.findutils
      pkgs.jq
    ];
    # hyprctl comes from PATH so it always matches the running compositor.
    text = ''
      cache=${lib.escapeShellArg "${config.xdg.cacheHome}/macos-wallpapers"}
      videos=${lib.escapeShellArg "${config.xdg.cacheHome}/wallpapers/videos"}
      link=${lib.escapeShellArg currentVideo}
      mkdir -p "$videos"

      # The largest screen, and the fastest refresh; then 240 halved until it fits that.
      monitors=$(hyprctl monitors -j)
      width=$(jq 'map(.width) | max' <<<"$monitors")
      height=$(jq 'map(.height) | max' <<<"$monitors")
      fps=$(jq '(map(.refreshRate) | max) as $hz | [240, 120, 60, 30] | map(select(. <= $hz + 1)) | first // 30' <<<"$monitors")
      size="''${width}x''${height}-''${fps}"

      # Until the image stops changing under us: set-wallpaper starts this on each change, and
      # systemd folds a start into a run that's already going.
      while :; do
        still=$(readlink -f ${lib.escapeShellArg current})
        name=$(basename "$still")
        # <slug>-<index>-<width>x<height>.jpg
        slug=''${name%-*-*}
        index=''${name#"$slug"-}
        index=''${index%%-*}
        place=$(jq -r .id "$(dirname "$still")/meta.json")

        # Image i of an aerial place is its i-th video by preferredOrder, as macos-wallpaper
        # numbers them; the place's subcategory is "AerialSubcategory" + its name without spaces.
        url=$(jq -r --arg key "AerialSubcategory''${place// /}" --argjson index "$index" '
          [.categories[].subcategories[]? | select(.localizedNameKey == $key) | .id] as $ids
          | [.assets[] | select(.["url-4K-SDR-240FPS"] and any(.subcategories[]?; IN($ids[])))]
          | sort_by(.preferredOrder // 0) | .[$index]["url-4K-SDR-240FPS"] // empty
        ' "$cache/aerials.json")
        if [ -z "$url" ]; then
          rm -f "$link"
          find "$videos" -mindepth 1 -delete
          exit 0
        fi

        clip="$videos/$slug-$index-$size.mp4"
        # Other pictures' clips, this one's at another size, and leftovers of an earlier run
        # for another image.
        find "$videos" -mindepth 1 ! -name "$slug-*-$size.mp4" ! -name ".$slug-$index.*" -delete

        if [ ! -e "$clip" ]; then
          rm -f "$link"
          source="$videos/.$slug-$index.mov"
          part="$videos/.$slug-$index.$size.mp4"
          curl -fsSL --retry 5 --continue-at - --cacert ${appleRootCa} -o "$source" "$url"
          if ! ffmpeg -nostdin -v error -hwaccel cuda -hwaccel_output_format cuda -i "$source" -an \
            -vf "fps=$fps,scale_cuda=$width:$height:format=p010le" \
            -c:v hevc_nvenc -profile:v main10 -preset p6 -tune hq -rc vbr -cq 20 -b:v 0 \
            -tag:v hvc1 -movflags +faststart -f mp4 -y "$part"; then
            echo "NVENC unavailable; encoding on the CPU" >&2
            ffmpeg -nostdin -v error -i "$source" -an \
              -vf "fps=$fps,scale=$width:$height:flags=lanczos,format=yuv420p10le" \
              -c:v libx265 -preset medium -crf 20 -tag:v hvc1 -movflags +faststart -f mp4 -y "$part"
          fi
          mv -f "$part" "$clip"
          rm -f "$source"
        fi

        if [ "$(readlink -f ${lib.escapeShellArg current})" = "$still" ]; then
          ln -sfn "$clip" "$link"
          exit 0
        fi
      done
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

  # The lock screen's clip of the current image (wallpaperVideo above): started by set-wallpaper
  # whenever the image changes, and at login in case an earlier run didn't finish. Downloading
  # and re-encoding takes a few minutes once per image; a no-op when the clip exists.
  systemd.user.services.wallpaper-video = {
    Unit = {
      Description = "Make the lock screen's clip of the macOS wallpaper";
      After = [
        "graphical-session.target"
        "macos-wallpaper.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe wallpaperVideo;
      Nice = 19;
      IOSchedulingClass = "idle";
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
