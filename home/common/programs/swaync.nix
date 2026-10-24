{ pkgs, self, ... }:

let
  theme = import "${self}/lib/theme" { inherit pkgs; };
in
{
  catppuccin.swaync = {
    enable = true;
    font = theme.fonts.default.name;
  };

  services.swaync = {
    enable = true;
    package = pkgs.swaynotificationcenter;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      # layer-shell = true;
      # cssPriority = "application";
      # Float the control center like the bar's popups instead of hugging the bar and screen edges.
      control-center-margin-top = 8;
      control-center-margin-bottom = 8;
      control-center-margin-right = 8;
      control-center-margin-left = 0;
      # notification-2fa-action = true;
      # notification-inline-replies = false;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 10;
      timeout-low = 5;
      timeout-critical = 0;
      fit-to-screen = true;
      control-center-width = 500;
      control-center-height = 600;
      notification-window-width = 500;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      # transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = false;

      # swaync's default widgets, declared so it stops logging "Config not found".
      widgets = [
        "inhibitors"
        "title"
        "dnd"
        "notifications"
      ];
      widget-config = {
        inhibitors = {
          text = "Inhibitors";
          button-text = "Clear All";
          clear-all-button = true;
        };
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd.text = "Do Not Disturb";
        notifications.vexpand = true;
      };
    };
  };
}
