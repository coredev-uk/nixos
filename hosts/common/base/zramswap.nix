_: {
  # zram is the only swap: no readahead; swapping to RAM beats dropping page cache, so swappiness > 100.
  boot.kernel.sysctl = {
    "vm.page-cluster" = 0;
    "vm.swappiness" = 180;
  };

  # No on-disk swap to hibernate to.
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  zramSwap = {
    algorithm = "lz4";
    enable = true;
  };
}
