{
  pkgs,
  lib,
  meta,
  ...
}:
{
  system.primaryUser = meta.username;
  system.stateVersion = lib.mkForce 6;

  users.users.${meta.username} = {
    name = meta.username;
    home = lib.mkForce "/Users/${meta.username}";
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQpQFDxvGq+x6sHldr81kFtftS6KFEzbOtoRKKTXFR7"
    ];

    packages = [ pkgs.home-manager ];
  };

  nix.settings = {
    trusted-users = [ meta.username ];
  };

}
