{
  self,
  lib,
  pkgs,
  meta,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  term = theme.meridian.terminal;
  ansi = [
    "black"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "white"
  ];
in
{
  # Fira Code and the Nerd Font symbols come from hosts/common/desktop on NixOS; darwin
  # hosts have no desktop module, so install them here (HM copies them into ~/Library/Fonts).
  home.packages = lib.optionals meta.isDarwin [
    theme.fonts.monospace.package
    theme.fonts.iconFont.package
  ];

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

    themes.meridian = {
      inherit (term) background foreground;
      cursor-color = term.cursor;
      # The cell under the gilt block cursor reads in ground, like text on any gilt fill.
      cursor-text = term.background;
      selection-background = term.selectionBackground;
      selection-foreground = term.selectionForeground;
      palette =
        lib.imap0 (i: name: "${toString i}=${term.normal.${name}}") ansi
        ++ lib.imap0 (i: name: "${toString (i + 8)}=${term.bright.${name}}") ansi;
    };

    package = if meta.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    enableZshIntegration = true;

    settings = {
      theme = "meridian";
      # Nerd Font glyphs (omp's `nerd` symbols, see ../shell/omp) from the symbols font
      # rather than Ghostty's built-in copy, so they track nixpkgs.
      font-family = [
        theme.fonts.monospace.name
        theme.fonts.iconFont.name
      ];
      # window-decoration = false;
      clipboard-paste-protection = false;
      # Close windows without asking, even with a running process (zellij keeps sessions).
      confirm-close-surface = false;
      # Option as Alt on macOS, so zellij's Alt chords work.
      macos-option-as-alt = lib.mkIf meta.isDarwin true;
      # Wrap ssh to install xterm-ghostty terminfo on remotes, falling back to
      # TERM=xterm-256color where that fails.
      shell-integration-features = "ssh-env,ssh-terminfo";

      # Tabs and splits are zellij's job (see ../shell/zellij.nix), so release the keys it
      # binds. Linux: Ghostty's Alt+digit tab switching and its new-tab shortcut. macOS: the
      # Cmd keys for Ghostty's tabs, splits and search, and Ctrl+Tab tab cycling, which zellij
      # binds the same way.
      keybind = map (key: "${key}=unbind") (
        if meta.isDarwin then
          [
            "super+t"
            "super+w"
            "super+shift+["
            "super+shift+]"
            "super+9"
            "super+d"
            "super+shift+d"
            "super+["
            "super+]"
            "super+f"
            "super+g"
            "ctrl+tab"
            "ctrl+shift+tab"
          ]
          ++ lib.concatMap (n: [
            "super+${toString n}"
            "super+digit_${toString n}"
          ]) (lib.range 1 8)
          ++
            lib.concatMap
              (arrow: [
                "super+alt+arrow_${arrow}"
                "super+ctrl+arrow_${arrow}"
              ])
              [
                "up"
                "down"
                "left"
                "right"
              ]
        else
          map (n: "alt+${toString n}") (lib.range 1 9)
          ++ map (n: "alt+digit_${toString n}") (lib.range 1 8)
          ++ [ "ctrl+shift+t" ]
      );
    };
  };
}
