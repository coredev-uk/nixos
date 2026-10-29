{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  m = theme.meridian;

  # A qtct colour scheme: one QPalette per state, colours in QPalette::ColorRole order. The
  # 22nd role (Accent) is only read by Qt 6.6+; qt5ct stops after the first 21.
  palette =
    overrides:
    lib.concatStringsSep ", " (
      map (role: overrides.${role} or base.${role}) [
        "windowText"
        "button"
        "light"
        "midlight"
        "dark"
        "mid"
        "text"
        "brightText"
        "buttonText"
        "base"
        "window"
        "shadow"
        "highlight"
        "highlightedText"
        "link"
        "linkVisited"
        "alternateBase"
        "noRole"
        "toolTipBase"
        "toolTipText"
        "placeholderText"
        "accent"
      ]
    );
  base = {
    windowText = m.text;
    button = m.plate;
    # Fusion bevels buttons and frames with light/midlight/dark/mid/shadow.
    light = m.hover;
    midlight = m.hover;
    dark = m.ground;
    mid = m.rule;
    text = m.text;
    brightText = m.text;
    buttonText = m.text;
    base = m.inset;
    window = m.ground;
    shadow = m.ground;
    highlight = m.gilt;
    highlightedText = m.ground;
    link = m.link;
    linkVisited = m.series4;
    alternateBase = m.plate;
    noRole = m.ground;
    toolTipBase = m.plate;
    toolTipText = m.text;
    placeholderText = m.muted;
    accent = m.gilt;
  };
  disabled = {
    windowText = m.muted;
    text = m.muted;
    buttonText = m.muted;
    highlight = m.rule;
    highlightedText = m.muted;
    accent = m.rule;
  };
  colorScheme = ''
    [ColorScheme]
    active_colors=${palette { }}
    inactive_colors=${palette { }}
    disabled_colors=${palette disabled}
  '';

  qtctSettings = qtct: {
    Appearance = {
      style = "Fusion";
      custom_palette = true;
      color_scheme_path = "${config.xdg.configHome}/${qtct}/colors/meridian.conf";
      icon_theme = "Papirus-Dark";
    };
  };
in
{
  # Fusion drawn from a Meridian palette through qtct; the Papirus icons come from gtk.nix.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    qt5ctSettings = qtctSettings "qt5ct";
    qt6ctSettings = qtctSettings "qt6ct";
  };

  xdg.configFile = {
    "qt5ct/colors/meridian.conf".text = colorScheme;
    "qt6ct/colors/meridian.conf".text = colorScheme;
  };
}
