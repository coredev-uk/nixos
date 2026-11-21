{
  config,
  lib,
  pkgs,
  self,
  meta,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  m = theme.meridian;
  # Vicinae colour object: the accent with an opacity on top (the shell's Theme.tint).
  giltTint = opacity: {
    name = "colors.core.accent";
    inherit opacity;
  };
  cfg = config.programs.vicinae;
  # Home Manager's copy of the app (copyApps): a path that survives updates, so macOS keeps its
  # Accessibility grant, which TCC ties to the bundle's path.
  darwinApp = "${config.home.homeDirectory}/Applications/Home Manager Apps/Vicinae.app";
in
lib.mkMerge [
  {
    # Home Manager's module with nixpkgs' vicinae on Linux. Layer shell is a vicinae setting
    # (launcher_window.layer_shell.enabled), on by default. The module asserts Linux, so on macOS
    # it stays off and the files and launchd agent below take its place, from the same options.
    programs.vicinae = {
      enable = !meta.isDarwin;
      # Declarative settings (theme and font) go to home-manager.json via VICINAE_OVERRIDES,
      # so settings.json stays writable by the app.
      mutableSettings = true;
      systemd.enable = true;

      # Written to $XDG_DATA_HOME/vicinae/themes/meridian.toml; anything left out is inherited
      # from vicinae-dark. Full key list: `vicinae theme template`.
      themes.meridian = {
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

      settings =
        lib.recursiveUpdate
          {
            theme = {
              dark.name = "meridian";
              light.name = "meridian";
            };
            font.normal.family = theme.fonts.shell.name;

            # File search unused (apps, calculator, power only). The indexer watched all of $HOME, looped
            # incremental scans on Go's build cache every ~1.5s, and grew its DB to 14 GB of rewrites on
            # the snapshotted /home subvolume, stalling btrfs commits for seconds.
            providers.files.preferences.autoIndexing = false;
          }
          # Linux opens it from Hyprland's bind (`vicinae open`); macOS has no such bind, so the
          # launcher's own global shortcut takes Cmd+Space (`cmd` is ⌘ there), which Spotlight
          # gives up in darwin-apps.nix.
          (
            lib.optionalAttrs meta.isDarwin {
              global_shortcuts.toggle = "cmd+space";

              # Proton Pass quick access on macOS, where the shell's widget (Quickshell, Wayland
              # only) can't run: the Raycast Store's Proton Pass extension, installed from Vicinae's
              # store. It keeps its own pass-cli, whose keychain entry trusts only that binary. Set up
              # like the widget: the same keys as its Hyprland bind (`super` is ⌃ on macOS, `cmd` ⌘),
              # website icons, items by name. No browser-tab suggestions: they need Raycast's browser
              # extension.
              providers."@izyuumi/store.raycast.proton-pass" = {
                preferences = {
                  showWebsiteIcons = true;
                  enableWebIntegration = false;
                };
                entrypoints.search-items = {
                  shortcut = "super+shift+space";
                  preferences.sortBy = "name";
                };
              };
            }
          );
    };
  }

  # macOS: what the module does on Linux, by hand. Same paths as Linux there (~/.config/vicinae,
  # ~/.local/share/vicinae), and the same VICINAE_OVERRIDES layering over the app's own
  # settings.json.
  (lib.mkIf meta.isDarwin (
    let
      overrides = "vicinae/home-manager.json";
    in
    {
      home.packages = [
        cfg.package
        theme.fonts.shell.package
      ];

      xdg.configFile.${overrides}.source =
        (pkgs.formats.json { }).generate "vicinae-settings"
          cfg.settings;
      xdg.dataFile = lib.mapAttrs' (
        name: value:
        lib.nameValuePair "vicinae/themes/${name}.toml" {
          source = (pkgs.formats.toml { }).generate "vicinae-${name}-theme" value;
        }
      ) cfg.themes;

      # The nix build makes no login item of its own (docs.vicinae.com/quickstart/macos).
      launchd.agents.vicinae = {
        enable = true;
        config = {
          ProgramArguments = [ "${darwinApp}/Contents/MacOS/Vicinae" ];
          EnvironmentVariables.VICINAE_OVERRIDES = "${config.xdg.configHome}/${overrides}";
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Interactive";
        };
      };
    }
  ))
]
