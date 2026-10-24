{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Not named after the source: the lock screen reads current.jpg from here too
  # (home/common/programs/quickshell/default.nix).
  wallpaperDir = "${config.xdg.cacheHome}/wallpapers";
  current = "${wallpaperDir}/current.jpg";

  # sylvan.apple.com, which serves the Aerials, chains to Apple's own root CA rather than one
  # in the system bundle. Pinned by hash, so the download can't be swapped.
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

  getWallpaper = pkgs.writeShellApplication {
    name = "get-wallpaper";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      ffmpeg-headless
      findutils
      gawk
      gnused
      gnutar
      jq
    ];
    runtimeEnv.AERIAL_CA_FILE = appleRootCa;
    # Fully self-contained: a missing dependency fails the build, not a login.
    inheritPath = false;
    # No pipefail: `… | head -n 1` may SIGPIPE its producer, which must not abort the script.
    bashOptions = [
      "errexit"
      "nounset"
    ];
    text = builtins.readFile ./wallpaper.sh;
  };

  # Grabs a new Aerial still (get-wallpaper's curl retries while the network comes up;
  # falls back to the newest cached one) and applies it, retrying until hyprpaper's IPC
  # socket accepts it.
  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper";
    runtimeInputs = [
      getWallpaper
      pkgs.coreutils
    ];
    # hyprctl comes from PATH so it always matches the running compositor.
    text = ''
      img=$(get-wallpaper) || img=$(get-wallpaper --existing)

      # hyprpaper's config points here, so the next login starts on this image.
      ln -sfn "$img" ${lib.escapeShellArg current}

      for _ in $(seq 1 30); do
        hyprctl hyprpaper wallpaper ",$img, cover" && exit 0
        sleep 1
      done
      echo "hyprpaper did not accept $img" >&2
      exit 1
    '';
  };
in
{
  services.hyprpaper = {
    enable = true;

    settings = {
      splash = false;

      # Shown as soon as hyprpaper starts, before aerial-wallpaper.service has grabbed a new one.
      wallpaper = [
        {
          monitor = "";
          path = current;
          fit_mode = "cover";
        }
      ];
    };
  };

  systemd.user.services.aerial-wallpaper = {
    Unit = {
      Description = "Grab and apply an Apple Aerial wallpaper";
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
      ExecStart = lib.getExe setWallpaper;
      Environment = [ "XDG_CACHE_HOME=${config.xdg.cacheHome}" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
