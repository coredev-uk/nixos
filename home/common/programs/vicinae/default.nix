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
  shared = import ./shared.nix { inherit theme; };
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

      themes.meridian = shared.meridian;

      settings =
        lib.recursiveUpdate shared.settings
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
