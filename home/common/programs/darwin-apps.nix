{ lib, ... }:
{
  # Raycast (Homebrew cask, hosts/poseidon/extra.nix) takes Cmd+Space, so Spotlight's two
  # hotkeys are off: 64 "Show Spotlight search" (Cmd+Space), 65 "Show Finder search window"
  # (Cmd+Option+Space). Added to the dict rather than set through targets.darwin.defaults,
  # which would replace AppleSymbolicHotKeys whole and re-enable every other one turned off in
  # System Settings. activateSettings applies them without logging out. Spotlight's index stays,
  # for Raycast's file search.
  home.activation.spotlightHotkeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for entry in "64 32 49 1048576" "65 32 49 1572864"; do
      set -- $entry
      run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" \
        "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>$2</integer><integer>$3</integer><integer>$4</integer></array><key>type</key><string>standard</string></dict></dict>"
    done
    run /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  # Spotlight's menu bar icon.
  targets.darwin.defaults."com.apple.Spotlight"."NSStatusItem VisibleCC Item-0" = false;

  # Tailscale (standalone) signs in to Headscale on the Oracle VPS instead of Tailscale's
  # servers; read as a system policy, so the app needs no "custom login server" step.
  targets.darwin.defaults."io.tailscale.ipn.macsys".LoginURL = "https://hs.hera.ac";

  # Its own "Launch at Login" toggle fails on macOS 27 (1.104.x never registers the
  # login item, logs "Could not find the launch daemon", flips back to off), so Tailscale
  # stays down after a reboot: tailscale/tailscale#18042. Drop once the cask ships the
  # SMAppService.mainApp fix (1.105+). -g: start in the background without stealing focus.
  launchd.agents.tailscale-app = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/open"
        "-g"
        "-a"
        "/Applications/Tailscale.app"
      ];
      RunAtLoad = true;
    };
  };
}
