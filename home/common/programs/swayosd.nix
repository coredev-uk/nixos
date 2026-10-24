{ pkgs, self, ... }:

let
  theme = import "${self}/lib/theme" { inherit pkgs; };
  c = theme.colours;
in
{
  # No Catppuccin port exists for SwayOSD; this restyles its default stylesheet with the
  # system palette, matching the bar popups (base background, accent border, radius 12).
  services.swayosd = {
    enable = true;
    stylePath = pkgs.writeText "swayosd-catppuccin.css" ''
      window#osd {
        border-radius: 12px;
        border: 2px solid ${c.accent};
        background: alpha(${c.base}, 0.95);
      }

      window#osd #container {
        margin: 16px;
      }

      window#osd image,
      window#osd label {
        color: ${c.text};
        font-family: "${theme.fonts.default.name}";
      }

      window#osd progressbar:disabled,
      window#osd image:disabled {
        opacity: 0.5;
      }

      window#osd progressbar,
      window#osd segmentedprogress {
        min-height: 6px;
        border-radius: 999px;
        background: transparent;
        border: none;
      }

      window#osd trough,
      window#osd segment {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: ${c.surface1};
      }

      window#osd progress,
      window#osd segment.active {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: ${c.accent};
      }

      window#osd segment {
        margin-left: 8px;
      }

      window#osd segment:first-child {
        margin-left: 0;
      }
    '';
  };
}
