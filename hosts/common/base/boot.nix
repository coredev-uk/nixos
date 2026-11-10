_: {

  # NOTE: This workaround was added for an old issue. If you're not experiencing
  # boot issues related to vconsole setup, this can likely be removed.
  # Test by removing and rebuilding - if boot works fine, delete permanently.
  # systemd.services.systemd-vconsole-setup = {
  #   unitConfig = {
  #     After = "local-fs.target";
  #   };
  # };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max"; # or auto
        # No editing the kernel command line at the boot menu; the LUKS root unlocks via TPM2.
        # lanzaboote copies this into loader.conf.
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
