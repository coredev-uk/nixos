{
  pkgs,
  ...
}:
let
  libx = import ./lib.nix { inherit (pkgs) lib; };
in
rec {
  inherit (libx) hexToRgb;

  catppuccin = {
    flavor = "mocha";
    accent = "blue";
  };

  colours = import ./colours.nix catppuccin.flavor;

  # catppuccin/gtk is archived upstream; adw-gtk3 matches the libadwaita apps instead.
  gtkTheme = {
    name = if catppuccin.flavor == "latte" then "adw-gtk3" else "adw-gtk3-dark";
    package = pkgs.adw-gtk3;
  };

  cursorTheme = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  fonts = {
    default = {
      name = "Inter";
      package = pkgs.inter;
      size = 11;
    };
    iconFont = {
      name = "Symbols Nerd Font";
      package = pkgs.nerd-fonts.symbols-only;
    };
    monospace = {
      name = "Fira Code";
      package = pkgs.fira-code;
    };
    emoji = {
      name = "Joypixels";
      package = pkgs.joypixels;
    };
  };
}
