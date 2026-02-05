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
    initrd.systemd.enable = true;

    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max"; # or auto
      };
      efi.canTouchEfiVariables = true;
    };
  };
}
