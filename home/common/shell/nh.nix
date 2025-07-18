{
  pkgs,
  meta,
  ...
}:
{
  programs.nh = {
    enable = true;
    package = pkgs.unstable.nh;
    flake = "${meta.flakePath}";
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 2";
    };
  };
}
