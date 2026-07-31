{ pkgs, ... }:
{
  # Raycast/Proton Mail/MediaMate have no update opt-out and reinstall to
  # /Applications regardless of launch path, so they're Homebrew casks
  # instead (hosts/poseidon/extra.nix).
  home.packages = with pkgs; [
    alt-tab-macos
    bartender
  ];

  # Disables AltTab's Sparkle auto-updater; version is pinned via the flake.
  targets.darwin.defaults."com.lwouis.alt-tab-macos".SUEnableAutomaticChecks = false;

  # Bartender: uncheck "Check for Updates Automatically" once in-app (no defaults key for it).
}
