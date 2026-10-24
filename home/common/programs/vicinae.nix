_: {
  catppuccin.vicinae.enable = true;

  # Home Manager's module with nixpkgs' vicinae. Layer shell is a vicinae setting
  # (launcher_window.layer_shell.enabled), on by default.
  programs.vicinae = {
    enable = true;
    # Declarative settings (the catppuccin theme) go to home-manager.json via
    # VICINAE_OVERRIDES, so settings.json stays writable by the app.
    mutableSettings = true;
    systemd.enable = true;
  };
}
