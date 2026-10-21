{
  self,
  lib,
  pkgs,
  meta,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  catppuccin.ghostty.enable = true;

  programs.ghostty = {
    enable = true;

    package = if meta.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    enableZshIntegration = true;

    settings = {
      font-family = theme.fonts.monospace.name;
      # window-decoration = false;
      clipboard-paste-protection = false;

      # Release Ghostty's default Alt+digit tab switching so zellij receives them
      # (see ../shell/zellij.nix).
      keybind =
        map (n: "alt+${toString n}=unbind") (lib.range 1 9)
        ++ map (n: "alt+digit_${toString n}=unbind") (lib.range 1 8);
    };
  };
}
