# Ghostty's Meridian theme and the settings every terminal shares: Ghostty (./default.nix) and
# Wintty, Ghostty's core on Windows, on athena (hosts/athena/windows).
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
    # The cell under the gilt block cursor reads in ground, like text on any gilt fill.
    cursor-text = term.background;
    selection-background = term.selectionBackground;
    selection-foreground = term.selectionForeground;
    palette =
      lib.imap0 (i: name: "${toString i}=${term.normal.${name}}") ansi
      ++ lib.imap0 (i: name: "${toString (i + 8)}=${term.bright.${name}}") ansi;
  };

  settings = {
    # Nerd Font glyphs (omp's `nerd` symbols, see ../../shell/omp) from the symbols font
    # rather than Ghostty's built-in copy, so they track nixpkgs.
    font-family = [
      theme.fonts.monospace.name
      theme.fonts.iconFont.name
    ];
    # window-decoration = false;
    clipboard-paste-protection = false;
    # Wrap ssh to install xterm-ghostty terminfo on remotes, falling back to
    # TERM=xterm-256color where that fails.
    shell-integration-features = "ssh-env,ssh-terminfo";
  };
}
