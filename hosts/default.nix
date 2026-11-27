{
  config,
  meta,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}:
let
  # Shared by nix.settings and Determinate's nix.custom.conf. attic.hera.ac/coredev holds what CI
  # builds for atlas, poseidon and hermes (.github/workflows/hosts.yml); Attic lives in home-ops.
  substituters = [
    "https://attic.hera.ac/coredev"
    "https://nix-citizen.cachix.org"
    "https://nix-community.cachix.org"
  ];
  trustedPublicKeys = [
    "coredev:g2+SrYgQg5HPBFIFHqHszqjvH7n52Zi3HVraAlY0kl8="
    "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
in
{
  imports = [
    (./. + "/${meta.hostname}/boot.nix")
    (./. + "/${meta.hostname}/hardware.nix")
  ]
  # Optional per-host extras
  ++ lib.optional (builtins.pathExists (
    ./. + "/${meta.hostname}/extra.nix"
  )) ./${meta.hostname}/extra.nix
  # Desktop config
  ++ lib.optional meta.isDesktop ./common/desktop;

  _module.args.theme = import ../lib/theme { inherit pkgs; };

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
    ];

    config = {
      allowUnfree = true;
      joypixels.acceptLicense = true;
    };
  };

  nix = lib.mkIf config.nix.enable {
    # Register every input but `self` (its source changes per commit, which rebuilt the system
    # and kept CI from skipping atlas as cached) and the non-flake inputs. nixpkgs comes from
    # the nixpkgs.flake.* defaults.
    registry = lib.mapAttrs (_: flake: { inherit flake; }) (
      removeAttrs inputs [
        "self"
        "nixpkgs"
        "impeccable"
        "taste-skill"
      ]
    );

    # Flakes only, no channels.
    channel.enable = false;

    optimise.automatic = true;
    settings = {
      warn-dirty = false;
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      inherit substituters;
      trusted-public-keys = trustedPublicKeys;
    };
  };

  # Determinate owns nix.conf when nix.enable is false (poseidon).
  environment.etc."nix/nix.custom.conf" = lib.mkIf (!config.nix.enable) {
    text = ''
      warn-dirty = false
      extra-substituters = ${lib.concatStringsSep " " substituters}
      extra-trusted-public-keys = ${lib.concatStringsSep " " trustedPublicKeys}
    '';
  };
}
