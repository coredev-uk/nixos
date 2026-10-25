# Firewall openings for the bar's Cast view (home/common/programs/airplay.nix and GNOME
# Network Displays).
_: {
  networking.firewall = {
    # AirPlay speakers send timing and control packets back to OwnTone on these ports.
    allowedUDPPorts = [
      6001
      6002
    ];

    # GNOME Network Displays serves the Chromecast stream from an HTTP server on a random port
    # (soup_server_listen_all with port 0), which the TV connects back to: allow the kernel's
    # ephemeral port range, from private networks only.
    extraCommands = ''
      for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
        iptables -A nixos-fw -p tcp -s "$net" --dport 32768:60999 -j nixos-fw-accept
      done
    '';
    extraStopCommands = ''
      for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
        iptables -D nixos-fw -p tcp -s "$net" --dport 32768:60999 -j nixos-fw-accept 2>/dev/null || true
      done
    '';
  };
}
