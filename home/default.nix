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
  ++ lib.optionals meta.isDarwin [
    ./common/programs/zen.nix
    ./common/programs/ghostty.nix
    ./common/programs/discord.nix
    ./common/programs/t3code.nix
    ./common/programs/darwin-apps.nix
  ];
  home = {
    inherit (meta) username;
    inherit (meta) homeDirectory;
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
