_: {
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    # Repeat offenders get exponentially longer bans across all jails.
    bantime-increment = {
      enable = true;
      maxtime = "48h";
      overalljails = true;
    };
    # Loopback (127.0.0.1/8, ::1) is always ignored by the NixOS module.
    ignoreIP = [
      "10.0.0.0/8"
      "192.168.0.0/16"
    ];
  };
}
