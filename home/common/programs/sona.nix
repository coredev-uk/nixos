{
  inputs,
  pkgs,
  self,
  ...
}:
let
  m = (import "${self}/lib/theme" { inherit pkgs; }).meridian;

  # Sona keeps text at 4.5:1 on ground, surface, raised, hover, active and a selected row. The
  # system palette's `muted` (3.6:1 on the ground) and `alert` (3.96:1 on a selected row) miss
  # that, and its `selection` is too light to carry text (text2 is 3.27:1 on it), so Sona gets
  # its own values: lightness raised in OKLCH just enough, hue and chroma kept (muted
  # #6d717a -> #969aa4, alert #e06c5a -> #ed7865), and `active` is hover's tone with `hover`
  # a step between raised and active. The system palette is unchanged.
  inkFaint = "#969aa4";
  danger = "#ed7865";
  hover = "#282e37";
in
{
  # Sona (github:coredev-uk/sona-go, its `nix` branch): the native Apple Music client. sona-nightly
  # is the newest published build, the nightly rc of main or the release when that is newer, with
  # the Last.fm and Discord credentials. It downloads the Widevine CDM from Google itself on first
  # start, into ~/.local/share/sona.
  home.packages = [ inputs.sona.packages.${pkgs.stdenv.hostPlatform.system}.sona-nightly ];

  # Meridian as a Sona theme (dark only), picked in Settings → Appearance. Sona reloads the file
  # on change.
  xdg.configFile."sona/themes/meridian.json".text = builtins.toJSON {
    format = 1;
    id = "meridian";
    name = "Meridian";
    author = "Paul (system palette)";
    dark.color = {
      ground = m.ground;
      surface = m.inset;
      raised = m.plate;
      inherit hover;
      active = m.hover;
      line = m.rule;
      control-line = m.muted;
      ink = m.text;
      ink-muted = m.text2;
      ink-faint = inkFaint;
      amber = m.gilt;
      amber-ink = m.gilt;
      on-amber = m.ground;
      inherit danger;
      positive = m.ok;
    };
  };
}
