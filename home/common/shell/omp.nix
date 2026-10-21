{ pkgs, ... }:
{
  # oh-my-pi coding agent (https://omp.sh)
  home.packages = [ pkgs.unstable.omp ];

  home.file.".omp/agent/config.yml" = {
    force = true;
    source = (pkgs.formats.yaml { }).generate "omp-config.yml" {
      symbolPreset = "unicode";
      composer.shape = "box";
      theme = {
        dark = "titanium";
        light = "light";
      };
      setupVersion = 2;
    };
  };
}
