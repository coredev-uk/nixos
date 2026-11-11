{ pkgs, config, ... }:
let
  ifExists = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  user = "paul";
in
{
  users.users.${user} = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.zsh;
    extraGroups = [
      "audio"
      "networkmanager"
      "users"
      "video"
      "wheel"
    ]
    ++ ifExists [
      "docker"
      "plugdev"
      "render"
      "lxd"
      "gamemode" # polkit only lets this group change the governor, GPU and procsys
      "i2c" # For RGB
    ];

    linger = true;

    # The Atlas key in Proton Pass (Development vault), served by its SSH agent
    # (home/common/shell/ssh.nix); only for logging in here, separate from the GitHub key.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkaCsF9IeeIU3ScdvVlUMfWw6Km4i6uImVoUfZWB2vq paul@atlas"
    ];

    packages = [ pkgs.home-manager ];
  };

  # This is a workaround for not seemingly being able to set $EDITOR in home-manager
  environment.sessionVariables = {
    EDITOR = "vim";
  };
}
