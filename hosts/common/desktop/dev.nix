_: {
  # For HMR (development with Vite/Webpack). The open-file limit comes from systemd's
  # DefaultLimitNOFILE (hosts/common/desktop/gaming.nix), which the uwsm session inherits.
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_user_watches" = 524288; # Also recommended
  };
}
