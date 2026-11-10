_: {

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # No cups-browsed: CUPS itself lists driverless (IPP Everywhere/AirPrint) printers found over
  # mDNS as temporary queues, so the network-facing browse daemon adds nothing.
  services.printing = {
    enable = true;
    browsed.enable = false;
  };
}
