{
  config,
  hostname,
  inputs,
  lib,
  outputs,
  stateVersion,
  desktop,
  ...
}:
{
  imports =
    [
      (./. + "/${hostname}/boot.nix")
      (./. + "/${hostname}/hardware.nix")
    ]
    # Extras
    ++ lib.optional (builtins.pathExists (./. + "/${hostname}/extra.nix")) ./${hostname}/extra.nix
    # Include desktop config if a desktop is defined
    ++ lib.optional (builtins.isString desktop) ./common/desktop;

  nixpkgs = {
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      inputs.agenix.overlays.default

      # Or just specify overlays directly here, for example:
      # (_: _: { embr = inputs.embr.packages."${pkgs.system}".embr; })
    ];

    config = {
      allowUnfree = true;
      joypixels.acceptLicense = true;
      permittedInsecurePackages = [ ];
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mkForce (lib.mapAttrs (_: value: { flake = value; }) inputs);

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mkForce (
      lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry
    );

    optimise.automatic = true;
    settings = {
      warn-dirty = false; # Disable warning about dirty working directory - annoying af
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };

  system = {
    stateVersion = lib.mkDefault stateVersion;
  };
}
