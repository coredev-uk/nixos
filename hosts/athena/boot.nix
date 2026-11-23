{ inputs, meta, ... }:
{
  # NixOS-WSL for athena (atlas's Windows install; Windows side: ./windows). No bootloader.
  imports = [
    inputs.nixos-wsl.nixosModules.default

    ../common/base
    ../common/users/${meta.username}
  ];

  wsl = {
    enable = true;
    defaultUser = meta.username;
  };

  # Never bump: gates stateful migrations.
  system.stateVersion = "26.05";
}
