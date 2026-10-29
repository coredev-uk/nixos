{ self, pkgs, ... }:
let
  m = (import "${self}/lib/theme" { inherit pkgs; }).meridian;
in
{
  programs.atuin = {
    enable = true;

    daemon.enable = true;

    enableZshIntegration = true;

    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://atuin.hera.ac";
      theme.name = "meridian";
    };
  };

  # Base stays unset so it is the terminal's foreground (atuin's advice for themes that only
  # recolour the accents).
  xdg.configFile."atuin/themes/meridian.toml".source =
    (pkgs.formats.toml { }).generate "atuin-theme-meridian"
      {
        theme.name = "meridian";
        colors = {
          AlertInfo = m.ok;
          AlertWarn = m.caution;
          AlertError = m.alert;
          Annotation = m.text2;
          Guidance = m.text2;
          Important = m.gilt;
          Title = m.text;
          Muted = m.muted;
          SyntaxCommand = m.terminal.normal.green;
          SyntaxFlag = m.terminal.normal.cyan;
          SyntaxString = m.terminal.normal.yellow;
          SyntaxVariable = m.terminal.normal.cyan;
          SyntaxOperator = m.terminal.normal.magenta;
          SyntaxComment = m.terminal.bright.black;
        };
      };
}
