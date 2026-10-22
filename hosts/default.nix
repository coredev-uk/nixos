{
  config,
  meta,
  inputs,
  lib,
  outputs,
  ...
}:
let
  # Shared between nix.settings below and Determinate's nix.custom.conf.
  substituters = [
    "https://cache.nixos.org"
    "https://catppuccin.cachix.org"
    "https://nix-citizen.cachix.org"
    "https://nix-community.cachix.org"
    "https://vicinae.cachix.org"
  ];
  trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
    "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
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
      permittedInsecurePackages = [ ];
    };
  };

  nix = lib.mkIf config.nix.enable {
    # Register every other flake input so nix3 commands (`nix run home-manager`, …)
    # use the locked revisions. `nixpkgs` itself, and NIX_PATH's `nixpkgs=flake:nixpkgs`,
    # come from the nixpkgs.flake.setFlakeRegistry/setNixPath defaults.
    registry = lib.mapAttrs (_: flake: { inherit flake; }) (removeAttrs inputs [ "nixpkgs" ]);

    optimise.automatic = true;
    settings = {
      warn-dirty = false; # Disable warning about dirty working directory - annoying af
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Binary caches
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
