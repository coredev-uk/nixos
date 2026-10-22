# Shell for bootstrapping flake-enabled nix and home-manager.
# Flake-only (needs the locked pkgs): enter with 'nix develop'.
{ pkgs }:
{
  default = pkgs.mkShell {
    name = "coredev-uk-flake";
    # Enable experimental features without having to specify the argument
    NIX_CONFIG = "experimental-features = nix-command flakes";
    nativeBuildInputs =
      with pkgs;
      [
        nix
        home-manager
        git
      ]
      # Secure Boot key tooling for install-with-disk; Linux-only.
      ++ lib.optional stdenv.hostPlatform.isLinux sbctl;
  };
}
