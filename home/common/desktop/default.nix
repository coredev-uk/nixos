{
  pkgs,
  meta,
  ...
}:
{
  imports = [
    (./. + "/${meta.desktop}")

    ./default/gtk.nix
    ./default/qt.nix
    ./default/xdg.nix

    ../scripts

    ../programs/discord.nix
    ../programs/gaming.nix
    ../programs/kraken-lcd
    ../programs/ghostty
    ../programs/sona.nix
    ../programs/t3code.nix
    ../programs/zen.nix
  ];

  home.packages = with pkgs; [
    desktop-file-utils
    file-roller
    # Not in nixpkgs (pkgs/jellium-desktop).
    jellium-desktop
    # Plezy over Plex Desktop: it publishes MPRIS (the official app doesn't), which the shell's
    # now-playing needs (quickshell services/Media.qml). Patched in overlays/default.nix.
    plezy
    loupe
    mpv
    nautilus
    papers
    # proton-drive-cli omitted until nixpkgs builds it again (needs Bun 1.4.2, nixpkgs has 1.4.4).
    protonmail-desktop
    proton-pass
    proton-pass-cli
    proton-vpn-cli
  ];

  # pass-cli's default kernel keyring is denied here and wiped on reboot; use gnome-keyring.
  home.sessionVariables.PROTON_PASS_LINUX_KEYRING = "dbus";
}
