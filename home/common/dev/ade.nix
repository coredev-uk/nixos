{ inputs, pkgs, ... }:
{
  # ADE (github:coredev-uk/ade). Its config lives in ~/.config/ade/config.toml, which ADE writes
  # itself (`ade init`, `ade project add`), so it is not managed here. git, gh, zellij, lazygit and
  # nvim come from the shell and dev modules; delta draws ADE's review diffs.
  home.packages = [
    inputs.ade.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.delta
  ];
}
