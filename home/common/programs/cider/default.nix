{
  lib,
  pkgs,
  self,
  ...
}:
let
  m = (import "${self}/lib/theme" { inherit pkgs; }).meridian;

  # "#c9a24f" -> "201, 162, 79", for the translucent selection.
  rgb =
    hex:
    lib.concatMapStringsSep ", " (i: toString (lib.fromHexString (builtins.substring i 2 hex))) [
      1
      3
      5
    ];
in
{
  home.packages = [ pkgs.cider-2 ];

  # Cider 2 picks up any directory under its themes folder (Settings → Themes). The rules are
  # Catppuccin for Cider's (MIT, marketplace theme 12) with its palette block swapped for
  # Meridian's; they only ever name these variables, so the palette lives here. Cider runs every
  # stylesheet through postcss-nested, so the nesting needs no build step.
  xdg.configFile = {
    "sh.cider.genten/themes/meridian/theme.yml".text = ''
      name: Meridian
      author: paul
      stylesheets:
        - name: Meridian
          file: main.css
          description: The system palette (lib/theme)
    '';

    "sh.cider.genten/themes/meridian/main.css".text = ''
      /* Meridian for Cider 2, generated from lib/theme by home/common/programs/cider. */
      body.body--dark {
        --accent: ${m.gilt};
        --text: ${m.text};
        --subtext1: ${m.text};
        --subtext0: ${m.text2};
        --overlay1: ${m.text2};
        --overlay0: ${m.muted};
        --surface0: ${m.rule};
        --base: ${m.plate};
        --mantle: ${m.inset};
        --crust: ${m.ground};

        --selection-bg: rgba(${rgb m.gilt}, 0.22);
        --red: ${m.alert};
        --green: ${m.ok};
        --blue: ${m.link};

      ${builtins.readFile ./rules.css}'';
  };
}
