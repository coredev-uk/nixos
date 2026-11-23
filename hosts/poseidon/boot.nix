{
  pkgs,
  lib,
  meta,
  ...
}:
{
  system.primaryUser = meta.username;
  # Never bump.
  system.stateVersion = 6;

  # nix-darwin only sets UserShell for users it manages; else the account keeps /bin/zsh while
  # zellij runs the nix zsh. Activation rewrites only PrimaryGroupID and UserShell here (uid
  # matches, RealName untouched without `description`).
  users.knownUsers = [ meta.username ];
  # So chsh and others accept the login shell.
  environment.shells = [ pkgs.zsh ];

  users.users.${meta.username} = {
    name = meta.username;
    uid = 501;
    home = lib.mkForce "/Users/${meta.username}";
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQpQFDxvGq+x6sHldr81kFtftS6KFEzbOtoRKKTXFR7"
    ];

    packages = [ pkgs.home-manager ];
  };
}
