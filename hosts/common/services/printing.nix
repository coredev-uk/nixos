_: {

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # No cups-browsed: CUPS lists driverless (IPP Everywhere/AirPrint) mDNS printers itself.
  services.printing = {
    enable = true;
    browsed.enable = false;
  };
}
