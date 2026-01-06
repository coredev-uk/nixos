{ lib, meta, ... }:
{
  imports = [
    ./base.nix
    ../programs/zellij.nix
  ]
  ++ lib.optional meta.isDesktop ./gui.nix;
}
