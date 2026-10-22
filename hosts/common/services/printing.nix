_: {

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # cups-filters is always in the CUPS bindir; cups-browsed runs because avahi is on.
  services.printing.enable = true;
}
