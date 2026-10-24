{ pkgs, self, ... }:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  # Kvantum theme + kvantum.kvconfig come from catppuccin.kvantum (enabled via catppuccin.enable).
  qt =
    let
      qtctSettings.Appearance.icon_theme = "Papirus-${
        if theme.catppuccin.flavor == "latte" then "Light" else "Dark"
      }";
    in
    {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "kvantum";
      qt5ctSettings = qtctSettings;
      qt6ctSettings = qtctSettings;
    };
}
