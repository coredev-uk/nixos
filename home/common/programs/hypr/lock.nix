{
  self,
  pkgs,
  meta,
  ...
}:
let
  theme = import "${self}/lib/theme" {
    inherit pkgs;
    inherit (meta) hostname;
  };
  inherit (theme) hexToRgb colours;
in
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 10;
        ignore_empty_input = false;
      };

      # Smooth animations for modern look
      animations = {
        enabled = true;
        bezier = "smooth, 0.25, 0.1, 0.25, 1";
        animation = [
          "fadeIn, 1, 5, smooth"
          "fadeOut, 1, 5, smooth"
          "inputFieldDots, 1, 2, smooth"
          "inputFieldColors, 1, 4, smooth"
        ];
      };

      background = [
        {
          monitor = "";
          path = "$HOME/.cache/current-wallpaper.jpg";
          blur_passes = 3;
          blur_size = 7;
          noise = 0.0117;
          contrast = 0.8917;
          brightness = 0.8172;
          vibrancy = 0.1686;
          vibrancy_darkness = 0.0;
        }
      ];

      # Modern input field with gradient border
      input-field = [
        {
          monitor = "";
          size = "300, 60";
          outline_thickness = 3;
          dots_size = 0.25;
          dots_spacing = 0.3;
          dots_center = true;
          outer_color = "rgba(${hexToRgb colours.purple}, 0.8)";
          inner_color = "rgba(${hexToRgb colours.bgDark}, 0.5)";
          font_color = "rgb(${hexToRgb colours.text})";
          fade_on_empty = true;
          fade_timeout = 2000;
          placeholder_text = "<i>Enter Password...</i>";
          hide_input = false;
          rounding = 15;
          check_color = "rgba(${hexToRgb colours.green}, 0.8)";
          fail_color = "rgba(${hexToRgb colours.red}, 0.8)";
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          capslock_color = "rgba(${hexToRgb colours.yellow}, 0.8)";
          position = "0, -120";
          halign = "center";
          valign = "center";
          font_family = theme.fonts.default.name;
          shadow_passes = 2;
          shadow_size = 3;
          shadow_color = "rgba(0, 0, 0, 0.5)";
        }
      ];

      label = [
        # Current time
        {
          monitor = "";
          text = "$TIME";
          color = "rgba(${hexToRgb colours.text}, 1.0)";
          font_size = 90;
          font_family = theme.fonts.default.name;
          position = "0, 150";
          halign = "center";
          valign = "center";
          shadow_passes = 2;
          shadow_size = 3;
          shadow_color = "rgba(0, 0, 0, 0.5)";
        }
        # Date
        {
          monitor = "";
          text = ''cmd[update:60000] echo "$(date +"%A, %d %B")"'';
          color = "rgba(${hexToRgb colours.subtext1}, 1.0)";
          font_size = 28;
          font_family = theme.fonts.default.name;
          position = "0, 60";
          halign = "center";
          valign = "center";
          shadow_passes = 2;
          shadow_size = 3;
          shadow_color = "rgba(0, 0, 0, 0.5)";
        }
        # User greeting
        {
          monitor = "";
          text = ''cmd[update:60000] echo "Hello, $(echo $USER | sed 's/./\U&/')!"'';
          color = "rgba(${hexToRgb colours.subtext0}, 0.8)";
          font_size = 20;
          font_family = theme.fonts.default.name;
          position = "0, -200";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
