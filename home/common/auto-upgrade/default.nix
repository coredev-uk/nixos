# Standalone configs (atlas, athena) follow main like system.autoUpgrade, and say what changed.
# Not services.home-manager.autoUpgrade: without useFlake (a local checkout) it runs
# `nix-channel --update` first, which recreates ~/.nix-defexpr/channels.
{
  config,
  lib,
  pkgs,
  meta,
  osConfig ? null,
  ...
}:
let
  report = pkgs.writeShellApplication {
    name = "upgrade-report";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      jq
      libnotify
      nix
      nvd
    ];
    # report.sh's directive only reaches treefmt; the wrapper's prelude moves it off the top.
    excludeShellChecks = [ "SC2016" ];
    text = builtins.readFile ./report.sh;
  };

  upgrade = pkgs.writeShellApplication {
    name = "home-manager-auto-upgrade";
    runtimeInputs = [
      config.programs.home-manager.package
      pkgs.curl
      pkgs.nix
      report
    ];
    text = ''
      # A catch-up run at login can start before the network is up. Nix then switches to its cached
      # copy of main instead of failing, and the report finds nothing new: wait until GitHub answers.
      for _ in $(seq 180); do
        curl --silent --fail --max-time 10 --output /dev/null \
          https://api.github.com/repos/coredev-uk/nixos/commits/HEAD && break
        sleep 10
      done
      # Retry for half an hour.
      for attempt in 1 2 3 4 5 6; do
        if home-manager switch --refresh --flake github:coredev-uk/nixos#${meta.username}@${meta.hostname}; then
          exec upgrade-report home-success
        fi
        [ "$attempt" -eq 6 ] || sleep 300
      done
      upgrade-report home-failure
      exit 1
    '';
  };
in
lib.mkIf (osConfig == null) {
  home.packages = [ report ];

  systemd.user = {
    timers.home-manager-auto-upgrade = {
      Unit.Description = "Home Manager upgrade timer";
      Timer = {
        OnCalendar = "05:30";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
    services.home-manager-auto-upgrade = {
      Unit = {
        Description = "Home Manager upgrade";
        # The switch it runs mustn't restart it.
        X-SwitchMethod = "keep-old";
      };
      Service.ExecStart = lib.getExe upgrade;
    };

    # Started by nixos-upgrade.service (hosts/atlas/extra.nix) with system-<result>.
    services."upgrade-report@" = {
      Unit.Description = "Nix upgrade report (%i)";
      Service = {
        Type = "oneshot";
        ExecStart = "${lib.getExe report} %i";
      };
    };
  };
}
