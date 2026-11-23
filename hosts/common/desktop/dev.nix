_: {
  # HMR (Vite/Webpack). Open-file limit: DefaultLimitNOFILE in gaming.nix.
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_user_watches" = 524288;
  };
}
