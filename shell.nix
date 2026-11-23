# Bootstrap shell; flake-only (needs the locked pkgs): 'nix develop'.
{ pkgs }:
{
  default = pkgs.mkShell {
    name = "coredev-uk-flake";
    NIX_CONFIG = "experimental-features = nix-command flakes";
    nativeBuildInputs =
      with pkgs;
      [
        nix
        home-manager
        git
      ]
      # Secure Boot key tooling for install-with-disk
      ++ lib.optional stdenv.hostPlatform.isLinux sbctl;
  };
}
