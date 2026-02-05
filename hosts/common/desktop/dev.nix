_: {
  # For HMR (development with Vite/Webpack)
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_user_watches" = 524288; # Also recommended
  };

  # For PAM sessions
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "-";
      item = "nofile";
      value = "524288"; # Match systemd limit
    }
  ];
}
