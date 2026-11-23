{
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

  # Standalone (atlas) follows main like system.autoUpgrade; not with useFlake (local checkout).
  services.home-manager.autoUpgrade = lib.mkIf (osConfig == null) {
    enable = true;
    frequency = "05:30";
    flags = [
      "--refresh"
      "--flake"
      "github:coredev-uk/nixos#${meta.username}@${meta.hostname}"
    ];
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
