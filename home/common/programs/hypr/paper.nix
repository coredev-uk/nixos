{
  services.hyprpaper = {
    enable = true;

    settings = {
      splash = false;

      wallpaper = [
        {
          monitor = "";
          path = "~/.local/cache/bing-wallpapers";
          fit_mode = "cover";
        }
      ];
    };
  };

}
