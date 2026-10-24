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

  # Each Ghostty surface runs in a transient systemd scope; this prefix drop-in applies to
  # all of them. Interactive zsh (e.g. zellij panes, whose pty zellij keeps open) ignores
  # SIGTERM, so stopping the scope at shutdown/logout hung until the 90s timeout. SIGHUP
  # makes the shells exit; the shorter timeout bounds anything else that ignores both.
  xdg.configFile."systemd/user/app-ghostty-surface-transient-.scope.d/stop.conf" =
    lib.mkIf (!meta.isDarwin)
      {
        text = ''
          [Scope]
          SendSIGHUP=yes
          TimeoutStopSec=10s
        '';
      };

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

      # Tabbing is zellij's job (see ../shell/zellij.nix):
      # - release Ghostty's default Alt+digit tab switching so zellij receives them
      # - drop the new-tab shortcut (Ctrl+Shift+T on Linux, Cmd+T on macOS)
      keybind =
        map (n: "alt+${toString n}=unbind") (lib.range 1 9)
        ++ map (n: "alt+digit_${toString n}=unbind") (lib.range 1 8)
        ++ [ (if meta.isDarwin then "super+t=unbind" else "ctrl+shift+t=unbind") ];
    };
  };
}
