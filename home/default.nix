{
  config,
  lib,
  outputs,
  meta,
  pkgs,
  osConfig ? null,
  ...
}:
{
  imports = [
    ./common/shell
    ./common/dev
  ]
  ++ lib.optional meta.isDesktop ./common/desktop
  ++ lib.optional meta.isWSL ./common/wsl.nix
  ++ lib.optionals meta.isDarwin [
    ./common/programs/apps.nix
    ./common/programs/darwin-apps.nix
  ]
  # Optional per-host extras, as hosts/<host>/extra.nix
  ++ lib.optional (builtins.pathExists ./hosts/${meta.hostname}.nix) ./hosts/${meta.hostname}.nix;

  _module.args.theme = import ../lib/theme { inherit pkgs; };

  home = {
    inherit (meta) username;
    inherit (meta) homeDirectory;
  };

  # Standalone configs (atlas, athena) follow main like system.autoUpgrade. Not
  # services.home-manager.autoUpgrade: without useFlake (a local checkout) it runs
  # `nix-channel --update` first, which recreates ~/.nix-defexpr/channels.
  systemd.user = lib.mkIf (osConfig == null) {
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
        StartLimitIntervalSec = "1h";
        StartLimitBurst = 6;
      };
      Service = {
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "home-manager-auto-upgrade";
            runtimeInputs = [
              config.programs.home-manager.package
              pkgs.nix
            ];
            text = "home-manager switch --refresh --flake github:coredev-uk/nixos#${meta.username}@${meta.hostname}";
          }
        );
        # A catch-up run at login can start before the network is up.
        Restart = "on-failure";
        RestartSec = "5min";
      };
    };
  };

  # Standalone home-manager only; under nix-darwin, useGlobalPkgs hands HM the system's pkgs.
  nixpkgs = lib.mkIf (osConfig == null) {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
    ];

    config = {
      allowUnfree = true;
    };
  };
}
