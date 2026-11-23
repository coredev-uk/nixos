{ pkgs, options, ... }:
{

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries =
    options.programs.nix-ld.libraries.default
    ++ (with pkgs; [
      electron
      glib
      nss
      nspr
      atk
      cups
      dbus
      dbus-glib
      libdrm
      gtk2
      gtk3
      pango
      cairo
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libgbm
      expat
      libxcb
      libxkbcommon
      alsa-lib
      libusb1
      libGL.out
      libunwind.out
    ]);
}
