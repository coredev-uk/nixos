{ meta, ... }:
{
  # Determinate Nix manages the install (more resilient across macOS upgrades). Before the first
  # `darwin-rebuild switch`:
  #   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  nix.enable = false;

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = meta.username;
    autoMigrate = true;
    # Only casks: /opt/homebrew/bin is empty and `brew` is already on PATH.
    enableZshIntegration = false;
  };

  # reattach: Touch ID inside zellij/tmux.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  # Name used by `nh darwin switch`/darwin-rebuild to find darwinConfigurations.poseidon.
  networking = {
    hostName = meta.hostname;
    localHostName = meta.hostname;
  };

  system.defaults = {
    finder = {
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv";
    };
    NSGlobalDomain.AppleShowAllExtensions = true;
    dock = {
      show-recents = false;
      tilesize = 80;
    };
  };

  # Home-manager's zsh runs compinit and sets the prompt. nix-darwin's compinit would share
  # ~/.zcompdump between /bin/zsh 5.9 and zellij's nix zsh 5.9.2, which rebuild it each time (~2s per window).
  programs.zsh = {
    enableGlobalCompInit = false;
    enableBashCompletion = false;
    promptInit = "";
  };

  # Apps that self-update straight into /Applications go through Homebrew (split: darwin-apps.nix).
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false; # slow tap refresh on every rebuild
      upgrade = false;
      cleanup = "zap";
    };

    casks = [
      "proton-mail"
      "protonvpn"
      "proton-drive"
      "proton-pass"
      "mediamate"
      # Standalone variant; two tailscaleds (with services.tailscale) fight over tunnel and DNS.
      "tailscale-app"
    ];
  };
}
