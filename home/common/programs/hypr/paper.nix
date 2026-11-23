{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Names from `macos-wallpaper list`: dynamic landscapes that follow the sun. First six are desktop
  # pictures, last three aerial-video places. Offered by quickshell's WallpaperPicker (Super+Shift+P).
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

  # Read by the quickshell wallpaper instance and lock screen.
  current = "${config.xdg.cacheHome}/wallpapers/current.jpg";

  macosWallpaper = inputs.macos-wallpapers.packages.${pkgs.stdenv.hostPlatform.system}.default;
  macosWallpaperArgs = [
    "--cache-dir"
    "${config.xdg.cacheHome}/macos-wallpapers"
    # Same location as wlsunset (sunset.nix).
    "--latitude"
    config.services.wlsunset.latitude
    "--longitude"
    config.services.wlsunset.longitude
  ]
  ++ lib.concatMap (picture: [
    "--picture"
    picture
  ]) pictures;

  # set-wallpaper [current | set NAME]: resolve the image for now (of NAME after switching) and apply
  # it only if changed, so timer runs are cheap.
  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper";
    runtimeInputs = [
      macosWallpaper
      pkgs.coreutils
      pkgs.systemd
      pkgs.util-linux
    ];
    # quickshell from PATH: same one the wallpaper instance runs.
    text = ''
      # Timer and keybind can overlap.
      exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/set-wallpaper.lock"
      flock 9

      if [ "$#" -eq 0 ]; then set -- current; fi
      img=$(macos-wallpaper "$@" ${lib.escapeShellArgs macosWallpaperArgs})
      [ "$(readlink ${lib.escapeShellArg current} || true)" = "$img" ] && exit 0

      # The wallpaper instance starts on this link.
      mkdir -p "$(dirname ${lib.escapeShellArg current})"
      ln -sfn "$img" ${lib.escapeShellArg current}

      # Lock screen clip of the old image is stale; wallpaper-video rebuilds it in the background.
      rm -f ${lib.escapeShellArg currentVideo} /var/lib/greeter-wallpaper/wallpaper.mp4
      systemctl --user start --no-block wallpaper-video.service

      # Greeter can't read this cache, so it gets a copy (dir: hosts/common/desktop/greeter.nix).
      # wallpaper-video copies the clip there.
      greeter=/var/lib/greeter-wallpaper
      if [ -w "$greeter" ]; then
        cp -f "$img" "$greeter/wallpaper.jpg.part" && mv -f "$greeter/wallpaper.jpg.part" "$greeter/wallpaper.jpg"
      fi

      # Crossfade the running wallpaper instance (quickshell/wallpaper/shell.qml); if not running it starts on the link.
      if systemctl --user is-active --quiet quickshell-wallpaper.service; then
        for _ in $(seq 1 10); do
          quickshell ipc --config wallpaper call wallpaper change "$img" && exit 0
          sleep 1
        done
        echo "the wallpaper instance did not take $img" >&2
        exit 1
      fi
    '';
  };

  # sylvan.apple.com (aerial videos) chains to Apple's own root CA, not the system bundle; pinned by
  # hash like macos-wallpapers (which doesn't export its copy).
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

  # Lock screen's moving background (quickshell/config/lock/LockVideo.qml): the aerial video the
  # current image is a frame of, as current.mp4 next to current.jpg. Apple's 4K HEVC 240 fps source
  # would saturate the GPU decoder, so the clip is made once per image at the largest screen's size and
  # 240/2^k fps fitting the fastest refresh (120 for 144-165 Hz), 10-bit. Clips of the current picture
  # are kept; non-aerial pictures (HEIC) have none.
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
    # hyprctl from PATH matches the running compositor.
    text = ''
      cache=${lib.escapeShellArg "${config.xdg.cacheHome}/macos-wallpapers"}
      videos=${lib.escapeShellArg "${config.xdg.cacheHome}/wallpapers/videos"}
      link=${lib.escapeShellArg currentVideo}
      greeter=/var/lib/greeter-wallpaper
      greeter_clip="$greeter/wallpaper.mp4"
      mkdir -p "$videos"

      # Largest screen and fastest refresh; fps is 240 halved until it fits.
      monitors=$(hyprctl monitors -j)
      width=$(jq 'map(.width) | max' <<<"$monitors")
      height=$(jq 'map(.height) | max' <<<"$monitors")
      fps=$(jq '(map(.refreshRate) | max) as $hz | [240, 120, 60, 30] | map(select(. <= $hz + 1)) | first // 30' <<<"$monitors")
      size="''${width}x''${height}-''${fps}"

      # Loop until the image stops changing: set-wallpaper restarts this on each change (systemd folds it into a running one).
      while :; do
        still=$(readlink -f ${lib.escapeShellArg current})
        name=$(basename "$still")
        # <slug>-<index>-<width>x<height>.jpg
        slug=''${name%-*-*}
        index=''${name#"$slug"-}
        index=''${index%%-*}
        place=$(jq -r .id "$(dirname "$still")/meta.json")

        # Image i of an aerial place is its i-th video by preferredOrder (as macos-wallpaper numbers them);
        # subcategory key is "AerialSubcategory" + name without spaces.
        url=$(jq -r --arg key "AerialSubcategory''${place// /}" --argjson index "$index" '
          [.categories[].subcategories[]? | select(.localizedNameKey == $key) | .id] as $ids
          | [.assets[] | select(.["url-4K-SDR-240FPS"] and any(.subcategories[]?; IN($ids[])))]
          | sort_by(.preferredOrder // 0) | .[$index]["url-4K-SDR-240FPS"] // empty
        ' "$cache/aerials.json")
        if [ -z "$url" ]; then
          rm -f "$link" "$greeter_clip"
          find "$videos" -mindepth 1 -delete
          exit 0
        fi

        clip="$videos/$slug-$index-$size.mp4"
        # Drop other pictures' clips, other sizes and stale partials.
        find "$videos" -mindepth 1 ! -name "$slug-*-$size.mp4" ! -name ".$slug-$index.*" -delete

        if [ ! -e "$clip" ]; then
          rm -f "$link" "$greeter_clip"
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
          # Greeter plays it from a readable copy; skipped if already this clip (size+mtime).
          if [ -w "$greeter" ] && [ "$(stat -c %s.%Y "$clip")" != "$(stat -c %s.%Y "$greeter_clip" 2>/dev/null || true)" ]; then
            cp -fp "$clip" "$greeter_clip.part" && mv -f "$greeter_clip.part" "$greeter_clip"
          fi
          # set-wallpaper may have changed the image during the copy; loop again.
          if [ "$(readlink -f ${lib.escapeShellArg current})" = "$still" ]; then
            exit 0
          fi
        fi
      done
    '';
  };

  # Picker cards: low-res image per picture, as JSON. First call builds the copies (downloads each picture once).
  wallpaperPreviews = pkgs.writeShellApplication {
    name = "wallpaper-previews";
    runtimeInputs = [ macosWallpaper ];
    text = ''
      exec macos-wallpaper previews ${lib.escapeShellArgs macosWallpaperArgs}
    '';
  };

in
{
  # Called by name from quickshell's WallpaperPicker.
  home.packages = [
    setWallpaper
    wallpaperPreviews
  ];

  systemd.user.services.macos-wallpaper = {
    Unit = {
      Description = "Show the macOS wallpaper for the sun's position";
      # Explicit After=graphical-session.target avoids a cycle with quickshell-wallpaper that the
      # implicit one from WantedBy would create, stalling session startup.
      After = [
        "graphical-session.target"
        "quickshell-wallpaper.service"
      ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe setWallpaper} current";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Lock screen clip of the current image (wallpaperVideo): started by set-wallpaper on change and at
  # login in case a run didn't finish. Takes minutes per image; no-op if the clip exists.
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

  # Builds picker previews for pictures lacking them (new names in the list); no-op otherwise.
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

  # Images a dynamic picture lands between are >= 1 h apart, so 10 min is enough.
  systemd.user.timers.macos-wallpaper = {
    Unit = {
      Description = "Keep the macOS wallpaper in step with the sun";
      PartOf = [ "graphical-session.target" ];
    };
    Timer.OnCalendar = "*:0/10";
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
