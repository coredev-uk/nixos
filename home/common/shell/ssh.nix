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

  onePassword = meta.passwordManager == "1password";

  toTOML = (pkgs.formats.toml { }).generate "1Password-Agents";
  opAgentMac = "${meta.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";

  # pass-cli's own SSH agent (`pass-cli ssh-agent start`) serves the keys of the signed-in Proton
  # Pass account. The socket is the CLI's documented default location.
  protonAgentSock = "${meta.homeDirectory}/.ssh/proton-pass-agent.sock";
  SSH_AUTH_SOCK =
    if !onePassword then
      protonAgentSock
    else if meta.isDarwin then
      opAgentMac
    else
      "${meta.homeDirectory}/.1password/agent.sock";
  IdentityAgent = lib.replaceStrings [ " " ] [ "\\ " ] SSH_AUTH_SOCK;

  # The agent as a user service. It needs the session `pass-cli login` leaves behind (the bar's
  # Proton Pass window signs in on atlas), so it fails while signed out and tries again.
  protonAgent = pkgs.writeShellApplication {
    name = "proton-pass-ssh-agent";
    runtimeInputs = [ pkgs.proton-pass-cli ] ++ lib.optional (!meta.isDarwin) pkgs.util-linux;
    text = ''
      export PROTON_PASS_NO_UPDATE_CHECK=1
    ''
    + lib.optionalString (!meta.isDarwin) ''
      # The kernel keyring is denied and wiped on reboot (home/common/desktop/default.nix).
      export PROTON_PASS_LINUX_KEYRING=dbus

      # Any pass-cli call during a pending web login deletes the half-made session; the login
      # (quickshell-pass, scripts/pass.sh) holds this lock exclusively, so stay out of its way.
      exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/quickshell-pass.lock"
      flock -s -n 9 || {
        echo "A Proton Pass sign-in is pending" >&2
        exit 1
      }
      pass-cli info >/dev/null
      exec 9>&-
    ''
    + ''
      rm -f ${lib.escapeShellArg protonAgentSock}
      exec pass-cli ssh-agent start --socket-path ${lib.escapeShellArg protonAgentSock}
    '';
  };

  # Public halves of the SSH keys (`ssh-add -L`), which must be in the password manager: the
  # 1Password items, or the same keys imported into Proton Pass (`pass-cli item create ssh-key
  # import`). With IdentitiesOnly, ssh offers only the matching agent key to each host rather
  # than every key the agent holds.
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

  xdg.configFile."1Password/ssh/agent.toml" = lib.mkIf onePassword {
    source = toTOML {
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
  };

  systemd.user.services.proton-pass-ssh-agent = lib.mkIf (!onePassword && !meta.isDarwin) {
    Unit = {
      Description = "Proton Pass SSH agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe protonAgent;
      Restart = "on-failure";
      RestartSec = 30;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  launchd.agents.proton-pass-ssh-agent = lib.mkIf (!onePassword && meta.isDarwin) {
    enable = true;
    config = {
      ProgramArguments = [ (lib.getExe protonAgent) ];
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ThrottleInterval = 30;
    };
  };

  # atlas gets pass-cli from home/common/desktop; poseidon has no desktop module.
  home.packages = lib.mkIf (!onePassword && meta.isDarwin) [ pkgs.proton-pass-cli ];

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
