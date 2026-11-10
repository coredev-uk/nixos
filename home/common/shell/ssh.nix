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
  IdentityAgent = lib.replaceStrings [ " " ] [ "\\ " ] SSH_AUTH_SOCK;

  # Public halves of the 1Password keys below (`ssh-add -L`). With IdentitiesOnly, ssh offers
  # only the matching agent key to each host rather than every key in the vault.
  publicKeys = {
    github = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQpQFDxvGq+x6sHldr81kFtftS6KFEzbOtoRKKTXFR7 GitHub";
    bitbucket = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIdMAFq7cpWew49M/6U6en4t9NEy4vm12YHMHUYXC8VY BitBucket";
    oracle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6ahRcvyUrGhwAHI9afIwkjkh6TJbCiqocgdmXvZgNO Oracle";
  };
  identity = name: {
    IdentityFile = "~/.ssh/${name}.pub";
    IdentitiesOnly = "yes";
  };
in
{
  home.file = {
    ".ssh/common_hosts".text = fullKnownHostsContent;
  }
  // lib.mapAttrs' (
    name: key: lib.nameValuePair ".ssh/${name}.pub" { text = key + "\n"; }
  ) publicKeys;

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
  };

  # Enable the SSH program for your user
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        inherit IdentityAgent;
        UserKnownHostsFile = "~/.ssh/common_hosts ~/.ssh/known_hosts";
        ControlMaster = "auto";
        ControlPath = "~/.ssh/cm-%C";
        ControlPersist = "10m";
        ServerAliveInterval = 30;
      };

      "github.com" = {
        HostName = "github.com";
        User = "git";
      }
      // identity "github";

      "bitbucket.org" = {
        User = "git";
        HostName = "bitbucket.org";
      }
      // identity "bitbucket";

      "aur.archlinux.org" = {
        User = "aur";
        HostName = "aur.archlinux.org";
      };

      "130.162.183.212" = {
        User = "ubuntu";
      }
      // identity "oracle";
    };
  };
}
