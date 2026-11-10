{
  lib,
  meta,
  pkgs,
  ...
}:
{
  programs.btop = {
    enable = true;
    # GPU monitoring needs the CUDA build (atlas has an Nvidia card).
    package = lib.mkIf (!meta.isDarwin) pkgs.btop-cuda;
    # The built-in TTY theme draws with the terminal's 16 colours, on the terminal's own
    # background, so btop follows Ghostty's palette.
    settings = {
      color_theme = "TTY";
      theme_background = false;
    };
  };
}
