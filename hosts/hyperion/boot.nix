{
  meta,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    ../common/base
    ../common/users/${meta.username}
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "sd_mod"
        "sdhci_pci"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];
      kernelModules = [ ];
    };

    kernelModules = [
      "kvm-intel"
      "vhost_vsock"
    ];

    kernel = {
      sysctl = {
        "fs.inotify.max_user_watches" = 524288;
      };
    };
  };
}
