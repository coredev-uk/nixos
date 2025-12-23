{ pkgs, ... }:
{
  programs.fastfetch = {
    enable = true;
  };

  home.file.".config/fastfetch/config.jsonc".source =
    "${pkgs.fastfetch}/share/fastfetch/presets/examples/25.jsonc";
}
