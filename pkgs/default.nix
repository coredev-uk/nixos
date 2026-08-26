# Custom packages, that can be defined similarly to ones from nixpkgs
# Build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  pkgs ? (import ../nixpkgs.nix) { },
}:
{
  beammp-launcher = pkgs.callPackage ./beammp-launcher.nix { };
  proton-drive-cli = pkgs.callPackage ./proton-drive-cli.nix { };
}
