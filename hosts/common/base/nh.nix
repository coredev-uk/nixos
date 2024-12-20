{
  pkgs,
  flakePath,
  ...
}:
{
  programs.nh = {
    enable = true;
    package = pkgs.unstable.nh;
    flake = "${flakePath}";
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 10d --keep 3";
    };
  };
}
