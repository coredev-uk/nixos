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
    "# AUR (fingerprint SHA256:RFzBCUItH9LZS0cKB5UE6ceAYhBD5C8GeOBip8Z11+4, from aur.archlinux.org)"
    "aur.archlinux.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuBKrPzbawxA/k2g6NcyV5jmqwJ2s+zpgZGZ7tpLIcN"
    ""
    "# VPS"
    "130.162.183.212 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+3rWNWdqywSQoSRfVyp6qAuHO1TQae3GwzsA7kinsq"
    ""
    "# atlas (its /etc/ssh/ssh_host_ed25519_key.pub)"
    "atlas ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOSWafFdU4bGttTPya205vZdasfISB9uv8v34syjjkPr"
  ];

  # Proton Pass's SSH agent serves its SSH key items: on Linux the desktop app's own (Settings →
  # SSH agent; the app starts with the session, home/common/desktop/hyprland), on macOS
  # pass-cli's launchd agent below for the Development vault (where Proton's docs put the socket).
  passCli = lib.getExe' pkgs.proton-pass-cli "pass-cli";
  agentSocket =
    if meta.isDarwin then
      "${meta.homeDirectory}/.ssh/proton-pass-agent.sock"
    else
      "${meta.homeDirectory}/.ssh/proton-pass-ssh-agent.sock";
  SSH_AUTH_SOCK = agentSocket;
  IdentityAgent = agentSocket;

  # Public halves of the agent's keys (`ssh-add -L`). With IdentitiesOnly, ssh offers only the
  # matching agent key to each host rather than every key in the vault.
  publicKeys = {
    github = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQpQFDxvGq+x6sHldr81kFtftS6KFEzbOtoRKKTXFR7 GitHub";
    bitbucket = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIdMAFq7cpWew49M/6U6en4t9NEy4vm12YHMHUYXC8VY BitBucket";
    oracle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6ahRcvyUrGhwAHI9afIwkjkh6TJbCiqocgdmXvZgNO Oracle";
    aur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPtuX2qOFQUxuH9wR/ZavxkjCherF9sKQJb1yYML21i AUR";
    # Logging in to atlas; its authorized key (hosts/common/users/paul/default.nix).
    atlas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkaCsF9IeeIU3ScdvVlUMfWw6Km4i6uImVoUfZWB2vq paul@atlas";
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

  home.sessionVariables = {
    inherit SSH_AUTH_SOCK;
  };

  # Signs in to Proton Pass on macOS (`pass-cli login`); Linux gets it with the desktop
  # (home/common/desktop/default.nix).
  home.packages = lib.optional meta.isDarwin pkgs.proton-pass-cli;

  # As Proton's docs set it up (protonpass.github.io/pass-cli/commands/ssh-agent). pass-cli keeps
  # its session in the login keychain; signed out, the agent exits and launchd retries a minute
  # later.
  launchd.agents.proton-pass-ssh-agent = lib.mkIf meta.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        passCli
        "ssh-agent"
        "start"
        "--socket-path"
        agentSocket
        "--vault-name"
        "Development"
      ];
      EnvironmentVariables.PROTON_PASS_NO_UPDATE_CHECK = "1";
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 60;
      StandardErrorPath = "${meta.homeDirectory}/Library/Logs/proton-pass-ssh-agent.log";
    };
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
      }
      // identity "aur";

      "atlas" = {
        User = meta.username;
      }
      // identity "atlas";

      "130.162.183.212" = {
        User = "ubuntu";
      }
      // identity "oracle";
    };
  };
}
