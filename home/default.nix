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
    ./common/programs/ghostty.nix
    ./common/programs/discord.nix
    ./common/programs/t3code.nix
    ./common/programs/darwin-apps.nix
    ./common/programs/vicinae.nix
  ];
  home = {
    inherit (meta) username;
    inherit (meta) homeDirectory;
  };

  # The standalone configuration (atlas's) follows main like the system (system.autoUpgrade,
  # hosts/atlas/extra.nix): home-manager-auto-upgrade.service switches to main's each morning, or
  # at the next login. Not with useFlake, which builds from a local checkout. The channel update it
  # runs first finds none (it leaves an empty channels profile).
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
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications

      # You can also add overlays exported from other flakes:
      # inputs.agenix.overlays.default
    ];

    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # permittedInsecurePackages = [ "electron-25.9.0" ];
    };
  };
}
