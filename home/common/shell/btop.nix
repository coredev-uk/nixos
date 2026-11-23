{
  lib,
  meta,
  pkgs,
  ...
}:
{
  programs.btop = {
    enable = true;
    # CUDA build for GPU monitoring.
    package = lib.mkIf (!meta.isDarwin) pkgs.btop-cuda;
    # TTY theme follows the terminal's 16-colour palette.
    settings = {
      color_theme = "TTY";
      theme_background = false;
    };
  };
}
