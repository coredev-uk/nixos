{
  pkgs,
  meta,
  lib,
  ...
}:

let
  fullKnownHostsContent = pkgs.lib.strings.concatLines [
    "# SSH Known Hosts File managed by NixOS Home Manager"
    "# GitHub"
    "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
    ""
    "# BitBucket"
    "bitbucket.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIazEu89wgQZ4bqs3d63QSMzYVa0MuJ2e2gKTKqu+UUO"
    ""
    "# AUR"
    "aur.archlinux.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPtuX2qOFQUxuH9wR/ZavxkjCherF9sKQJb1yYML21i"
    ""
    "# VPS"
    "130.162.183.212 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+3rWNWdqywSQoSRfVyp6qAuHO1TQae3GwzsA7kinsq"
  ];

  toTOML = (pkgs.formats.toml { }).generate "1Password-Agents";
  opAgentMac = "${meta.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  SSH_AUTH_SOCK = if meta.isDarwin then opAgentMac else "${meta.homeDirectory}/.1password/agent.sock";
  identityAgent = lib.replaceStrings [ " " ] [ "\\ " ] SSH_AUTH_SOCK;
in
{
  home.file.".ssh/common_hosts" = {
    text = fullKnownHostsContent;
    recursive = true;
  };

  xdg.configFile."1Password/ssh/agent.toml".source = toTOML {
    ssh-keys = [
      {
        item = "GitHub";
        vault = "Development";
      }
      {
        item = "BitBucket";
        vault = "Development";
      }
      {
        item = "Oracle";
        vault = "Development";
      }
    ];
  };

  home.sessionVariables = {
    inherit SSH_AUTH_SOCK;
    SSH_AGENT_PID = "";
  };

  # Enable the SSH program for your user
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        inherit identityAgent;
        userKnownHostsFile = "~/.ssh/common_hosts ~/.ssh/known_hosts";
      };

      "github.com" = {
        user = "git";
        hostname = "github.com";
        identityFile = "~/.ssh/github.pub";
        identitiesOnly = true;
      };

      "bitbucket.org" = {
        user = "git";
        hostname = "bitbucket.org";
      };

      "aur.archlinux.org" = {
        user = "aur";
        hostname = "aur.archlinux.org";
      };

      "130.162.183.212" = {
        user = "ubuntu";
      };
    };
  };

  # Agenix Identity
  age.identityPaths = [ "${meta.homeDirectory}/.ssh/github" ];
}
