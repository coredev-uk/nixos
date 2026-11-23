{ self, ... }:
{
  imports = [
    # VS Code's WSL server and other downloaded prebuilt binaries.
    "${self}/hosts/common/base/nix-ld.nix"
    # Windows-side files (windows/apply.ps1).
    ./windows
  ];
}
