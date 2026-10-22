_: {
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    # Loopback (127.0.0.1/8, ::1) is always ignored by the NixOS module.
    ignoreIP = [
      "10.0.0.0/8"
      "192.168.0.0/16"
    ];
  };
}
