{
  meta,
  ...
}:
{
  programs.nh = {
    enable = true;
    flake = "${meta.flakePath}";
    # NixOS hosts run the system-wide `nh clean all` (hosts/common/base), which
    # also covers user profiles. Darwin can't: nix-darwin's nh.clean requires
    # nix.enable, which Determinate Nix turns off.
    clean = {
      enable = meta.isDarwin;
      dates = "weekly";
      extraArgs = "--keep 3";
    };
  };
}
