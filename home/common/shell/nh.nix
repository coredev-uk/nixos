{ meta, ... }:
{
  programs.nh = {
    enable = true;
    flake = "${meta.flakePath}";
    # NixOS hosts clean system-wide (hosts/common/base); nix-darwin's nh.clean needs nix.enable,
    # which Determinate Nix disables.
    clean = {
      enable = meta.isDarwin;
      dates = "weekly";
      extraArgs = "--keep 3 --keep-since 3d";
    };
  };
}
