# Firewall openings for the bar's Cast view (AirPlay, GNOME Network Displays), private networks only.
_: {
  networking.firewall = {
    # AirPlay speakers send timing/control back to OwnTone on UDP 6001-6002. Network Displays
    # serves Chromecast over HTTP on a random port: allow the ephemeral range.
    extraCommands = ''
      for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
        iptables -A nixos-fw -p udp -s "$net" --dport 6001:6002 -j nixos-fw-accept
        iptables -A nixos-fw -p tcp -s "$net" --dport 32768:60999 -j nixos-fw-accept
      done
    '';
    extraStopCommands = ''
      for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
        iptables -D nixos-fw -p udp -s "$net" --dport 6001:6002 -j nixos-fw-accept 2>/dev/null || true
        iptables -D nixos-fw -p tcp -s "$net" --dport 32768:60999 -j nixos-fw-accept 2>/dev/null || true
      done
    '';
  };
}
