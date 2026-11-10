{ meta, ... }:
{
  # Determinate Nix manages the install instead of nix-darwin (more
  # resilient across macOS upgrades). One-time setup before the first
  # `darwin-rebuild switch`:
  #   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  nix.enable = false;

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = meta.username;
    autoMigrate = true; # adopt an existing manual Homebrew install if present
    # No `brew shellenv` in every shell: only casks are installed, so /opt/homebrew/bin is
    # empty, and `brew` itself is on PATH from the system profile.
    enableZshIntegration = false;
  };

  # reattach: Touch ID also works inside zellij/tmux, which run outside the GUI session.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # The flake's name for the machine, so `nh darwin switch` and darwin-rebuild find
  # darwinConfigurations.poseidon by hostname. computerName (Finder, AirDrop) stays as is.
  networking = {
    hostName = meta.hostname;
    localHostName = meta.hostname;
  };

  system.defaults = {
    finder = {
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv"; # list view
    };
    NSGlobalDomain.AppleShowAllExtensions = true;
    dock = {
      show-recents = false;
      tilesize = 80; # default is 64; bump if you want it even bigger
    };
  };

  programs._1password.enable = true;
  programs._1password-gui.enable = true;

  # Home-manager's zsh (oh-my-zsh) runs compinit and sets the prompt. nix-darwin's own
  # compinit in /etc/zshrc shares ~/.zcompdump between Ghostty's login shell (/bin/zsh 5.9)
  # and zellij's panes (nix zsh 5.9.2); each rejects the other's dump and rebuilds it,
  # ~2s per new window. Its prompt is overwritten by oh-my-posh anyway.
  programs.zsh = {
    enableGlobalCompInit = false;
    enableBashCompletion = false;
    promptInit = "";
  };

  # Apps with no update opt-out that reinstall straight to /Applications go
  # through Homebrew instead of nix (see darwin-apps.nix for the split).
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false; # skip the slow tap refresh on every rebuild
      upgrade = false;
      cleanup = "zap";
    };

    casks = [
      "raycast"
      "proton-mail"
      "protonvpn"
      "proton-drive"
      "proton-pass"
      "mediamate"
      # Standalone variant (menu bar app). Not alongside services.tailscale: two tailscaleds
      # fight over the tunnel and DNS. Login server: home/common/programs/darwin-apps.nix.
      "tailscale-app"
    ];
  };
}
