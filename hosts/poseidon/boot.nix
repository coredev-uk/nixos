{
  pkgs,
  lib,
  meta,
  ...
}:
{
  system.primaryUser = meta.username;
  # nix-darwin release of the first install; never bump it with upgrades.
  system.stateVersion = 6;

  users.users.${meta.username} = {
    name = meta.username;
    home = lib.mkForce "/Users/${meta.username}";
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQpQFDxvGq+x6sHldr81kFtftS6KFEzbOtoRKKTXFR7"
    ];

    packages = [ pkgs.home-manager ];
  };
}
