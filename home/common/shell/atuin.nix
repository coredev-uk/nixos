_: {
  programs.atuin = {
    enable = true;

    daemon.enable = true;

    enableZshIntegration = true;

    settings = {
      update_check = false;
      sync_address = "https://atuin.hera.ac";
    };
  };
}
