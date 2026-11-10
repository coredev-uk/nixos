{ pkgs, ... }:
{
  # Raycast/Proton Mail/MediaMate/Tailscale have no update opt-out and reinstall to
  # /Applications regardless of launch path, so they're Homebrew casks
  # instead (hosts/poseidon/extra.nix).
  home.packages = with pkgs; [
    alt-tab-macos
    bartender
  ];

  # Disables AltTab's Sparkle auto-updater; version is pinned via the flake.
  targets.darwin.defaults."com.lwouis.alt-tab-macos".SUEnableAutomaticChecks = false;

  # Tailscale (standalone) signs in to Headscale on the Oracle VPS instead of Tailscale's
  # servers; read as a system policy, so the app needs no "custom login server" step.
  targets.darwin.defaults."io.tailscale.ipn.macsys".LoginURL = "https://hs.hera.ac";

  # Bartender: uncheck "Check for Updates Automatically" once in-app (no defaults key for it).
}
