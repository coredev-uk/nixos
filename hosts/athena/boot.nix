{ inputs, meta, ... }:
{
  # NixOS-WSL under athena, atlas's Windows install (the Windows side: ./windows). WSL boots the
  # kernel and hands over to systemd; there is no bootloader here.
  imports = [
    inputs.nixos-wsl.nixosModules.default

    ../common/base
    ../common/users/${meta.username}
  ];

  wsl = {
    enable = true;
    defaultUser = meta.username;
  };

  # First-install release of this host. Never bump it with NixOS upgrades:
  # it gates stateful migrations, see `man configuration.nix` (system.stateVersion).
  system.stateVersion = "26.05";
}
