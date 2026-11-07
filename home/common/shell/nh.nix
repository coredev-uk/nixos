{
  lib,
  meta,
  ...
}:
{
  programs.nh = {
    enable = true;
    flake = "${meta.flakePath}";
    # nh picks the darwinConfiguration by the machine's hostname, which isn't the flake's
    # name for it; pin the attribute so a bare `nh darwin switch` works.
    darwinFlake = lib.mkIf meta.isDarwin "${meta.flakePath}#${meta.hostname}";
    # NixOS hosts run the system-wide `nh clean all` (hosts/common/base), which
    # also covers user profiles. Darwin can't: nix-darwin's nh.clean requires
    # nix.enable, which Determinate Nix turns off.
    clean = {
      enable = meta.isDarwin;
      dates = "weekly";
      extraArgs = "--keep 3 --keep-since 3d";
    };
  };
}
