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
  # Fira Code comes from hosts/common/desktop on NixOS; darwin hosts have no
  # desktop module, so install it here (HM copies it into ~/Library/Fonts).
  home.packages = lib.optional meta.isDarwin theme.fonts.monospace.package;

  catppuccin.ghostty.enable = true;

  programs.ghostty = {
    enable = true;

    package = if meta.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    enableZshIntegration = true;

    settings = {
      font-family = theme.fonts.monospace.name;
      # window-decoration = false;
      clipboard-paste-protection = false;
      # Wrap ssh to install xterm-ghostty terminfo on remotes, falling back to
      # TERM=xterm-256color where that fails.
      shell-integration-features = "ssh-env,ssh-terminfo";

      # Release Ghostty's default Alt+digit tab switching so zellij receives them
      # (see ../shell/zellij.nix).
      keybind =
        map (n: "alt+${toString n}=unbind") (lib.range 1 9)
        ++ map (n: "alt+digit_${toString n}=unbind") (lib.range 1 8);
    };
  };
}
