# GUI apps on every graphical host, NixOS (common/desktop) and macOS (home/default.nix).
{
  imports = [
    ./discord.nix
    ./ghostty
    ./t3code.nix
    ./vicinae
    ./zen.nix
  ];
}
