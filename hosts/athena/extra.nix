_: {
  imports = [
    ../common/services/auto-upgrade.nix
    # VS Code's WSL server and other downloaded prebuilt binaries.
    ../common/base/nix-ld.nix
    # Windows-side files (windows/apply.ps1).
    ./windows
  ];
}
