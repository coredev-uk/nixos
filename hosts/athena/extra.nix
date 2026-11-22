{ self, ... }:
{
  imports = [
    # VS Code's WSL server, and the other prebuilt Linux binaries tools download.
    "${self}/hosts/common/base/nix-ld.nix"
    # The files Windows' half takes from the flake (windows/apply.ps1).
    ./windows
  ];
}
