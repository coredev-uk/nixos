{ inputs, pkgs, ... }:
{
  # ADE writes its own ~/.config/ade/config.toml (`ade init`), so it is unmanaged. delta draws its review diffs.
  home.packages = [
    inputs.ade.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.delta
  ];
}
