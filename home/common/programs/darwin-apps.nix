{ lib, ... }:
{
  # Vicinae takes Cmd+Space: disable Spotlight hotkeys 64 (Cmd+Space) and 65 (Cmd+Option+Space).
  # dict-add rather than targets.darwin.defaults, which would replace AppleSymbolicHotKeys whole
  # and re-enable other hotkeys. Spotlight's index stays for Vicinae's file search.
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

  # Tailscale (standalone) logs in to Headscale via system policy, no manual login-server step.
  targets.darwin.defaults."io.tailscale.ipn.macsys".LoginURL = "https://hs.hera.ac";

  # Tailscale's own "Launch at Login" fails on macOS 27 (tailscale/tailscale#18042). Drop once the
  # cask ships the SMAppService.mainApp fix (1.105+). -g: don't steal focus.
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
