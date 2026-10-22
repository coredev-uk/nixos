{ pkgs, self, ... }:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  # Kvantum theme + kvantum.kvconfig come from catppuccin.kvantum (enabled via catppuccin.enable).
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  xdg.configFile."qt5ct/qt5ct.conf".source = (pkgs.formats.ini { }).generate "kvantum.kvconfig" {
    Appearance.icon_theme = "Papirus-${if theme.catppuccin.flavor == "latte" then "Light" else "Dark"}";
  };
}
