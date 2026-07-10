{
  pkgs,
  self,
  stable,
  config,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs stable; };
in
{
  home.pointerCursor = {
    inherit (theme.cursorTheme) package size name;
    enable = true;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;

    theme = theme.gtkTheme;

    font = {
      inherit (theme.fonts.default) package;
      name = "${theme.fonts.default.name}, ${theme.fonts.default.size}";
    };

    gtk2 = {
      configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
      extraConfig = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk3.extraConfig = {
      gtk-button-images = 1;
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.theme = null;
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  catppuccin.gtk.icon.enable = true;

  # Set color scheme for portals (modern standard)
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
