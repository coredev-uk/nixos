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

  # nix-darwin only sets the login shell (UserShell) of users it manages; without this the
  # account keeps /bin/zsh while zellij panes run the nix zsh. Activation only rewrites
  # PrimaryGroupID (gid, default 20 = staff) and UserShell here: uid matches the existing
  # account, RealName is left alone without `description`, and nix-darwin refuses to delete
  # the primary user.
  users.knownUsers = [ meta.username ];
  # /etc/shells, so chsh and anything else checking it accept the login shell.
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
