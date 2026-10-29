{
  lib,
  pkgs,
  self,
  config,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  m = theme.meridian;

  # libadwaita's named colours, recoloured with Meridian. adw-gtk3 (GTK 3) reads them as
  # @define-color; libadwaita 1.6+ (GTK 4) draws from the matching CSS variables and keeps the
  # named colours only for older apps, so GTK 4 gets both.
  colours = {
    accent_color = m.gilt;
    accent_bg_color = m.gilt;
    accent_fg_color = m.ground;

    # Text on the state fills is the ground: enamel on alert/ok/caution is too low contrast.
    destructive_color = m.alert;
    destructive_bg_color = m.alert;
    destructive_fg_color = m.ground;
    success_color = m.ok;
    success_bg_color = m.ok;
    success_fg_color = m.ground;
    warning_color = m.caution;
    warning_bg_color = m.caution;
    warning_fg_color = m.ground;
    error_color = m.alert;
    error_bg_color = m.alert;
    error_fg_color = m.ground;

    window_bg_color = m.ground;
    window_fg_color = m.text;
    view_bg_color = m.inset;
    view_fg_color = m.text;

    headerbar_bg_color = m.plate;
    headerbar_fg_color = m.text;
    headerbar_border_color = m.rule;
    headerbar_backdrop_color = m.ground;

    sidebar_bg_color = m.plate;
    sidebar_fg_color = m.text;
    sidebar_backdrop_color = m.plate;
    sidebar_border_color = m.rule;
    secondary_sidebar_bg_color = m.plate;
    secondary_sidebar_fg_color = m.text;
    secondary_sidebar_backdrop_color = m.plate;
    secondary_sidebar_border_color = m.rule;

    card_bg_color = m.plate;
    card_fg_color = m.text;
    popover_bg_color = m.plate;
    popover_fg_color = m.text;
    dialog_bg_color = m.plate;
    dialog_fg_color = m.text;
    thumbnail_bg_color = m.plate;
    thumbnail_fg_color = m.text;
    overview_bg_color = m.ground;
    overview_fg_color = m.text;
  };

  defineColours =
    extra:
    lib.concatLines (
      lib.mapAttrsToList (name: value: "@define-color ${name} ${value};") (colours // extra)
    );

  # GTK 3 has no CSS variables (it rejects them), and libadwaita derives its borders from
  # currentColor, so the 1px rule is set under each version's own name.
  gtk3Css = defineColours { borders = m.rule; };
  gtk4Css = ''
    ${defineColours { }}
    :root {
    ${
      lib.concatLines (
        lib.mapAttrsToList (name: value: "  --${lib.replaceStrings [ "_" ] [ "-" ] name}: ${value};") (
          colours // { border_color = m.rule; }
        )
      )
    }}
  '';
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

    # Papirus with its folders in paleorange, the papirus-folders colour nearest gilt.
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme.override { color = "paleorange"; };
    };

    font = {
      inherit (theme.fonts.default) package name size;
    };

    gtk2 = {
      configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
      extraConfig = ''
        gtk-application-prefer-dark-theme=1
      '';
    };

    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
      };
      extraCss = gtk3Css;
    };

    gtk4.extraCss = gtk4Css;
  };

  # Set color scheme for portals (modern standard)
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
