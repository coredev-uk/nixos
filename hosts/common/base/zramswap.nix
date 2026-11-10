_: {
  # zram is the only swap: no readahead (pages are decompressed one at a time anyway), and
  # swapping to RAM is cheaper than dropping page cache, hence swappiness above 100.
  boot.kernel.sysctl = {
    "vm.page-cluster" = 0;
    "vm.swappiness" = 180;
  };

  # Hibernate and hybrid-sleep won't work correctly without
  # an on-disk swap.
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Enable zramSwap
  zramSwap = {
    algorithm = "lz4";
    enable = true;
  };
}
