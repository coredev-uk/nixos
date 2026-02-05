{
  self,
  pkgs,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  catppuccin.ghostty.enable = true;

  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      font-family = theme.fonts.monospace.name;
      # window-decoration = false;
      clipboard-paste-protection = false;
    };
  };
}
