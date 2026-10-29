_: {
  programs.btop = {
    enable = true;
    # The built-in TTY theme draws with the terminal's 16 colours, on the terminal's own
    # background, so btop follows Ghostty's palette.
    settings = {
      color_theme = "TTY";
      theme_background = false;
    };
  };
}
