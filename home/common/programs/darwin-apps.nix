_:
{

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
