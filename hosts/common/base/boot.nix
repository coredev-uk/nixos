_: {

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
        # lanzaboote copies this into loader.conf; the LUKS root unlocks via TPM2.
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
