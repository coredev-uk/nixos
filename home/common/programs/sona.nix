{
  inputs,
  pkgs,
  self,
  ...
}:
let
  m = (import "${self}/lib/theme" { inherit pkgs; }).meridian;

  # Sona needs text at 4.5:1 on all its surfaces. System `muted` (3.6:1 on ground) and `alert` (3.96:1
  # on a selected row) miss that and `selection` is too light for text, so Sona gets its own values:
  # OKLCH lightness raised minimally (muted #6d717a -> #969aa4, alert #e06c5a -> #ed7865); `active` is
  # hover's tone and `hover` sits between raised and active.
  inkFaint = "#969aa4";
  danger = "#ed7865";
  hover = "#282e37";
in
{
  # Sona (github:coredev-uk/sona-go, `nix` branch): native Apple Music client; sona-nightly is the
  # newest build, with Last.fm/Discord credentials. Fetches the Widevine CDM itself on first start.
  home.packages = [ inputs.sona.packages.${pkgs.stdenv.hostPlatform.system}.sona-nightly ];

  # Meridian as a Sona theme (dark only); pick in Settings → Appearance.
  xdg.configFile."sona/themes/meridian.json".text = builtins.toJSON {
    format = 1;
    id = "meridian";
    name = "Meridian";
    author = "Paul (system palette)";
    dark.color = {
      inherit (m) ground;
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
