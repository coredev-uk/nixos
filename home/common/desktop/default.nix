{
  pkgs,
  meta,
  ...
}:
let
  # Plezy draws video into its own Wayland subsurface. On NVIDIA (no 10-bit EGL window configs
  # through 610.xx) it falls to a half-float (fp16) buffer, which it leaves undescribed while HDR
  # is off; Hyprland composites an undescribed fp16 buffer as linear light, so windowed video
  # came out blown out while fullscreen (scanned out raw) looked right. HDR is off here (SDR
  # desktop), so drop the fp16 tier: the plane gets an 8-bit sRGB buffer and Hyprland shows it
  # as is, windowed or fullscreen.
  plezy = pkgs.plezy.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace linux/runner/mpv/wayland_video_surface.cc \
        --replace-fail '{{10, false}, {16, true}, {8, false}}' '{{10, false}, {8, false}}'
    '';
  });
in
{
  imports = [
    (./. + "/${meta.desktop}")

    # Environment Configurations
    ./default/gtk.nix
    ./default/qt.nix
    ./default/xdg.nix

    ../scripts

    # Standard Programs
    ../programs/discord.nix
    ../programs/gaming.nix
    ../programs/kraken-lcd
    ../programs/ghostty.nix
    ../programs/sona.nix
    ../programs/t3code.nix
    ../programs/zen.nix
  ];

  home.packages = with pkgs; [
    desktop-file-utils
    file-roller
    # Plex (and Jellyfin) through Plezy rather than Plex Desktop: the official app has no MPRIS, so
    # the shell's now playing couldn't see or control it; Plezy publishes title, artwork and
    # controls over MPRIS (home/common/programs/quickshell, services/Media.qml). Patched above.
    plezy
    loupe
    mpv
    nautilus
    papers
    # proton-drive-cli is out until nixpkgs builds it again: 0.9.0's build demands Bun 1.4.2
    # exactly and nixpkgs ships 1.4.4.
    protonmail-desktop
    proton-pass
    proton-pass-cli
    proton-vpn-cli
  ];

  # pass-cli keeps its session key in the kernel keyring by default, which is denied here and
  # wiped on reboot; gnome-keyring (unlocked at login) keeps it instead.
  home.sessionVariables.PROTON_PASS_LINUX_KEYRING = "dbus";
}
