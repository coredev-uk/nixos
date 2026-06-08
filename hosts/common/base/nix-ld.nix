# ref: https://github.com/ywmaa/dotfiles/blob/main/nix-config/dynamic_binaries_support.nix

{ pkgs, options, ... }:
{

  programs.nix-ld.enable = true;

  ## If needed, you can add missing libraries here. nix-index-database is your friend to
  ## find the name of the package from the error message, like:
  ## $ nix run github:mic92/nix-index-database missinglib.so
  ## More details: https://github.com/nix-community/nix-index-database, you might like

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
