{
  lib,
  pkgs,
  self,
  ...
}:
let
  term = (import "${self}/lib/theme" { inherit pkgs; }).meridian.terminal;
  order = [
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
  console = {
    earlySetup = true;
    # Meridian's terminal palette (lib/theme). Colour 0 is the VT's background, so it is the
    # terminal background rather than the palette's black.
    colors = map (lib.removePrefix "#") (
      [ term.background ]
      ++ map (name: term.normal.${name}) (lib.tail order)
      ++ map (name: term.bright.${name}) order
    );
    packages = with pkgs; [
      terminus_font
      powerline-fonts
    ];
    font = "ter-powerline-v32n";
  };
}
