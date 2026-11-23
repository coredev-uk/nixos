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
      "gamemode" # polkit lets only this group change governor/GPU/procsys
      "i2c" # RGB
    ];

    linger = true;

    # Atlas key in Proton Pass (Development vault, via its SSH agent); login only, not the GitHub key.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkaCsF9IeeIU3ScdvVlUMfWw6Km4i6uImVoUfZWB2vq paul@atlas"
    ];

    packages = [ pkgs.home-manager ];
  };

  # $EDITOR can't be set via home-manager here
  environment.sessionVariables = {
    EDITOR = "vim";
  };
}
