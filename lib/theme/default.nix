{
  pkgs,
  stable ? pkgs,
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
    size = "standard";
  };

  colours = import ./colours.nix catppuccin.flavor;

  gtkTheme = {
    name = "catppuccin-${catppuccin.flavor}-${catppuccin.accent}-${catppuccin.size}";
    package = stable.catppuccin-gtk.override {
      inherit (catppuccin) size;
      variant = catppuccin.flavor;
      accents = [ catppuccin.accent ];
    };
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
