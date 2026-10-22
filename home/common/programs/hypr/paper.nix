{
  config,
  lib,
  pkgs,
  ...
}:
let
  wallpaperDir = "${config.xdg.cacheHome}/bing-wallpapers";
  current = "${wallpaperDir}/current.jpg";

  getWallpaper = pkgs.writeShellApplication {
    name = "get-wallpaper";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      findutils
      jq
    ];
    # Fully self-contained: a missing dependency fails the build, not a login.
    inheritPath = false;
    # No pipefail: `… | head -n 1` may SIGPIPE its producer, which must not abort the script.
    bashOptions = [
      "errexit"
      "nounset"
    ];
    text = builtins.readFile ./wallpaper.sh;
  };

  # Fetches a new Bing wallpaper (get-wallpaper's curl retries while the network comes up;
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

      # Shown as soon as hyprpaper starts, before bing-wallpaper.service has fetched a new one.
      wallpaper = [
        {
          monitor = "";
          path = current;
          fit_mode = "cover";
        }
      ];
    };
  };

  systemd.user.services.bing-wallpaper = {
    Unit = {
      Description = "Fetch and apply the Bing wallpaper";
      After = [ "hyprpaper.service" ];
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
