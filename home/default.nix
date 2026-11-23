{
  lib,
  outputs,
  meta,
  osConfig ? null,
  ...
}:
{
  imports = [
    ./common/shell
  ]
  ++ lib.optional (!meta.isHeadless) ./common/dev
  ++ lib.optional meta.isDesktop ./common/desktop
  ++ lib.optional meta.isWSL ./common/wsl.nix
  ++ lib.optionals meta.isDarwin [
    ./common/programs/zen.nix
    ./common/programs/ghostty
    ./common/programs/discord.nix
    ./common/programs/t3code.nix
    ./common/programs/darwin-apps.nix
    ./common/programs/vicinae
  ];
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
