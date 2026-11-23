# Meridian theme and settings shared by Ghostty (./default.nix) and Wintty on athena (hosts/athena/windows).
{ lib, theme }:
let
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
  meridian = {
    inherit (term) background foreground;
    cursor-color = term.cursor;
    # Text under the gilt block cursor is ground.
    cursor-text = term.background;
    selection-background = term.selectionBackground;
    selection-foreground = term.selectionForeground;
    palette =
      lib.imap0 (i: name: "${toString i}=${term.normal.${name}}") ansi
      ++ lib.imap0 (i: name: "${toString (i + 8)}=${term.bright.${name}}") ansi;
  };

  settings = {
    # Nerd symbols (omp's `nerd`) from the symbols font, not Ghostty's built-in copy.
    font-family = [
      theme.fonts.monospace.name
      theme.fonts.iconFont.name
    ];
    clipboard-paste-protection = false;
    # ssh installs xterm-ghostty terminfo on remotes, else falls back to xterm-256color.
    shell-integration-features = "ssh-env,ssh-terminfo";
  };
}
