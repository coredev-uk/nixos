# Vicinae's Meridian theme and the settings every host shares: Linux and macOS (./default.nix)
# and athena's Windows (hosts/athena/windows).
{ theme }:
let
  m = theme.meridian;
  # Vicinae colour object: the accent with an opacity on top (the shell's Theme.tint).
  giltTint = opacity: {
    name = "colors.core.accent";
    inherit opacity;
  };
in
{
  # Written to $XDG_DATA_HOME/vicinae/themes/meridian.toml (%LOCALAPPDATA%\vicinae\data\themes on
  # Windows); anything left out is inherited from vicinae-dark. Full key list: `vicinae theme template`.
  meridian = {
    meta = {
      version = 1;
      name = "Meridian";
      description = "The Quickshell shell's palette";
      variant = "dark";
      inherits = "vicinae-dark";
    };

    colors = {
      core = {
        background = m.plate;
        foreground = m.text;
        secondary_background = m.inset;
        border = m.rule;
        accent = m.gilt;
        accent_foreground = m.ground;
      };

      main_window = {
        border = m.rule;
        footer.background = m.inset;
      };
      settings_window.border = m.rule;

      accents = {
        blue = m.link;
        green = m.ok;
        magenta = m.series3;
        orange = m.caution;
        purple = m.series4;
        red = m.alert;
        yellow = m.gilt;
        cyan = m.series1;
      };

      shortcut.border = m.rule;

      text = {
        default = m.text;
        muted = m.text2;
        placeholder = m.muted;
        danger = m.alert;
        success = m.ok;
        selection = {
          background = m.selection;
          foreground = m.text;
        };
        links = {
          default = m.link;
          visited = m.series4;
        };
      };

      input = {
        border = m.rule;
        border_focus = m.gilt;
        border_error = m.alert;
      };

      button.primary = {
        background = m.gilt;
        foreground = m.ground;
        hover.background = m.giltHover;
        focus.outline = m.gilt;
      };

      # The shell's row language: hover fill, a gilt tint behind the selected row.
      list.item = {
        hover = {
          background = m.hover;
          foreground = m.text;
          secondary_foreground = m.text2;
        };
        selection = {
          background = giltTint 0.1;
          foreground = m.text;
          secondary_background = giltTint 0.16;
          secondary_foreground = m.text2;
        };
      };

      grid.item = {
        background = m.inset;
        hover.outline = m.rule;
        selection.outline = m.gilt;
      };

      scrollbars.background = m.rule;

      loading = {
        bar = m.gilt;
        spinner = m.text2;
      };
    };
  };

  settings = {
    theme = {
      dark.name = "meridian";
      light.name = "meridian";
    };
    font.normal.family = theme.fonts.shell.name;

    # File search unused (apps, calculator, power only). The indexer watched all of $HOME, looped
    # incremental scans on Go's build cache every ~1.5s, and grew its DB to 14 GB of rewrites on
    # the snapshotted /home subvolume, stalling btrfs commits for seconds.
    providers.files.preferences.autoIndexing = false;
  };
}
