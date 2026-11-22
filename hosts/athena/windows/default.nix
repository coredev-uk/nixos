# The Windows files athena's flake renders, for apply.ps1 (beside this file) to put in place:
#   wintty/config.wintty   Wintty (Ghostty's core on Windows): Ghostty's Meridian theme and shared
#                          settings (home/common/programs/ghostty-shared.nix)
#   vicinae/               Vicinae's Meridian theme and declarative settings
#                          (home/common/programs/vicinae-shared.nix)
#   fonts/                 the theme's monospace, icon and shell fonts, installed for the user
#   vscode/settings.json   VS Code's user settings
# Built with `nix build .#nixosConfigurations.athena.config.system.build.windows`. Every file is
# a copy, not a link: Windows can't follow a symlink into /nix/store over \\wsl.localhost.
{
  self,
  lib,
  pkgs,
  ...
}:
let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  ghostty = import "${self}/home/common/programs/ghostty-shared.nix" { inherit lib theme; };
  vicinae = import "${self}/home/common/programs/vicinae-shared.nix" { inherit theme; };

  # The format Home Manager writes Ghostty's config in: `key = value`, a list as repeated keys.
  winttyConfig = pkgs.writeText "config.wintty" (
    lib.generators.toKeyValue {
      listsAsDuplicateKeys = true;
      mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
    } (ghostty.meridian // ghostty.settings)
  );

  vicinaeTheme = (pkgs.formats.toml { }).generate "meridian.toml" vicinae.meridian;
  # Layered over the app's own (writable) settings.json through VICINAE_OVERRIDES, as Home
  # Manager does on Linux. Win+Space is Windows' input switcher, so the launcher takes Alt+Space,
  # PowerToys Run's key.
  vicinaeOverrides = (pkgs.formats.json { }).generate "home-manager.json" (
    lib.recursiveUpdate vicinae.settings { global_shortcuts.toggle = "alt+space"; }
  );

  fonts = with theme.fonts; [
    monospace
    iconFont
    shell
  ];

  fontFamily = lib.concatMapStringsSep ", " (f: "'${f.name}'") [
    theme.fonts.monospace
    theme.fonts.iconFont
  ];
  vscodeSettings = (pkgs.formats.json { }).generate "settings.json" {
    # Sona's style: gofumpt (`check` fails otherwise) and golangci-lint.
    gopls."formatting.gofumpt" = true;
    "go.lintTool" = "golangci-lint";
    "go.toolsManagement.autoUpdate" = false;
    "files.eol" = "\n";
    "editor.fontFamily" = fontFamily;
    "terminal.integrated.fontFamily" = fontFamily;
  };
in
{
  system.build.windows = pkgs.runCommand "athena-windows" { } ''
    install -Dm644 ${winttyConfig} $out/wintty/config.wintty
    install -Dm644 ${vicinaeTheme} $out/vicinae/meridian.toml
    install -Dm644 ${vicinaeOverrides} $out/vicinae/home-manager.json
    install -Dm644 ${vscodeSettings} $out/vscode/settings.json
    # One build of each face: Windows lists a family twice when it has both the .ttf and the
    # .otf, or a variable font beside its static cuts. Variable fonts first, then TrueType.
    mkdir -p $out/fonts
    for dir in ${lib.concatMapStringsSep " " (f: "${f.package}/share/fonts") fonts}; do
      # An array: a variable font's name ("…[wght].ttf") is a glob, which stdenv's nullglob drops.
      mapfile -t files < <(find "$dir" -type f \( -name '*\[*\].ttf' -o -name '*-VF.ttf' \))
      [ ''${#files[@]} -gt 0 ] || mapfile -t files < <(find "$dir" -type f -name '*.ttf')
      [ ''${#files[@]} -gt 0 ] || mapfile -t files < <(find "$dir" -type f -name '*.otf')
      install -m644 -t $out/fonts "''${files[@]}"
    done
  '';
}
