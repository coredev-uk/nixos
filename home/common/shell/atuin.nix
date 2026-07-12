_: {
  catppuccin.atuin.enable = true;

  programs.atuin = {
    enable = true;

    daemon.enable = true;

    enableZshIntegration = true;

    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://atuin.hera.ac";
    };
  };
}
