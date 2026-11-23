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
  # HM's copy of the app: stable path, so macOS keeps the Accessibility (TCC) grant across updates.
  darwinApp = "${config.home.homeDirectory}/Applications/Home Manager Apps/Vicinae.app";
in
lib.mkMerge [
  {
    # HM module on Linux (nixpkgs vicinae). It asserts Linux, so on macOS it's off and the files and
    # launchd agent below replace it, from the same options.
    programs.vicinae = {
      enable = !meta.isDarwin;
      # Declarative settings go to home-manager.json via VICINAE_OVERRIDES; settings.json stays app-writable.
      mutableSettings = true;
      systemd.enable = true;

      themes.meridian = shared.meridian;

      settings =
        lib.recursiveUpdate shared.settings
          # Linux opens via Hyprland's bind; macOS uses the launcher's own shortcut on Cmd+Space
          # (freed in darwin-apps.nix).
          (
            lib.optionalAttrs meta.isDarwin {
              global_shortcuts.toggle = "cmd+space";

              # Proton Pass quick access, since the shell's widget is Wayland-only: the Raycast Store
              # extension (keeps its own pass-cli, whose keychain entry trusts only that binary).
              # Mirrors the widget: same keys as the Hyprland bind (`super` = ⌃, `cmd` = ⌘), icons, by name.
              # No browser-tab suggestions (need Raycast's browser extension).
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

  # macOS: what the module does on Linux, by hand (same paths, same VICINAE_OVERRIDES layering).
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

      # The nix build has no login item (docs.vicinae.com/quickstart/macos).
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
