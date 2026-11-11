{
  config,
  meta,
  inputs,
  lib,
  outputs,
  ...
}:
let
  # Shared between nix.settings below and Determinate's nix.custom.conf. cache.nixos.org is
  # already the default substituter on both. nix-cache.hera.ac holds what GitHub Actions builds
  # for atlas and poseidon (.github/workflows/atlas.yml, nix-build.yml): an R2 bucket written
  # through niks3 in coredev-uk/home-ops (kubernetes/apps/nix-cache), public and reachable from
  # anywhere.
  substituters = [
    "https://nix-cache.hera.ac"
    "https://nix-citizen.cachix.org"
    "https://nix-community.cachix.org"
  ];
  trustedPublicKeys = [
    "nix-cache.hera.ac-1:Ayl31um+15Mbnobqt2XavEoQp1VJs3E5utf457d6NFY="
    "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
in
{
  imports = [
    (./. + "/${meta.hostname}/boot.nix")
    (./. + "/${meta.hostname}/hardware.nix")
  ]
  # Extras
  ++ lib.optional (builtins.pathExists (
    ./. + "/${meta.hostname}/extra.nix"
  )) ./${meta.hostname}/extra.nix
  # Include desktop config if a desktop is defined
  ++ lib.optional meta.isDesktop ./common/desktop;

  nixpkgs = {
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications

      # You can also add overlays exported from other flakes:
      # inputs.agenix.overlays.default

      # Or just specify overlays directly here, for example:
      # (_: _: { embr = inputs.embr.packages."${pkgs.system}".embr; })
    ];

    config = {
      allowUnfree = true;
      joypixels.acceptLicense = true;
    };
  };

  nix = lib.mkIf config.nix.enable {
    # Register every other flake input so nix3 commands (`nix run home-manager`, …)
    # use the locked revisions. `nixpkgs` itself, and NIX_PATH's `nixpkgs=flake:nixpkgs`,
    # come from the nixpkgs.flake.setFlakeRegistry/setNixPath defaults. The non-flake inputs
    # have nothing to run. Not `self`: its source changes with every commit, so registering it
    # rebuilt the system (registry.json, etc, activate) on commits that change nothing else, and
    # CI could never skip atlas as already cached.
    registry = lib.mapAttrs (_: flake: { inherit flake; }) (
      removeAttrs inputs [
        "self"
        "nixpkgs"
        "impeccable"
        "taste-skill"
      ]
    );

    # Flakes only: no root channel or channel NIX_PATH entries.
    channel.enable = false;

    optimise.automatic = true;
    settings = {
      warn-dirty = false; # Disable warning about dirty working directory - annoying af
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      inherit substituters;
      trusted-public-keys = trustedPublicKeys;
    };
  };

  # Determinate Nix owns nix.conf when nix.enable is false (see poseidon).
  environment.etc."nix/nix.custom.conf" = lib.mkIf (!config.nix.enable) {
    text = ''
      warn-dirty = false
      extra-substituters = ${lib.concatStringsSep " " substituters}
      extra-trusted-public-keys = ${lib.concatStringsSep " " trustedPublicKeys}
    '';
  };
}
