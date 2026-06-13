{
  config,
  pkgs,
  lib,
  modulesPath,
  meta,
  ...
}:
let
  # Set this after booting once with tpm2-measure-pcr enabled and recording:
  #   systemd-analyze pcrs 15 --json=short
  # Keep null until the real value is known, otherwise initrd will refuse to boot.
  expectedPcr15 = null;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    ../common/base
    ../common/users/${meta.username}
  ];

  environment.systemPackages = with pkgs; [
    efibootmgr
  ];

  boot = {
    # Secure boot configuration
    bootspec.enable = true;
    loader.systemd-boot.enable = lib.mkForce false;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    initrd = {
      availableKernelModules = [
        "ahci"
        "nvme"
        "sd_mod"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];

      systemd = {
        dbus.enable = true;
        tpm2.enable = true;
        storePaths = lib.mkIf (expectedPcr15 != null) [
          pkgs.jq
          "${config.boot.initrd.systemd.package}/bin/systemd-analyze"
        ];

        services.check-pcr15 = lib.mkIf (expectedPcr15 != null) {
          unitConfig.DefaultDependencies = "no";

          after = [ "cryptsetup.target" ];
          before = [ "sysroot.mount" ];
          requiredBy = [ "sysroot.mount" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          script = ''
            expected='${expectedPcr15}'
            actual="$(${config.boot.initrd.systemd.package}/bin/systemd-analyze pcrs 15 --json=short | ${pkgs.jq}/bin/jq -r '.[0].sha256')"

            if [ "$actual" != "$expected" ]; then
              echo "PCR15 verification failed"
              echo "expected: $expected"
              echo "actual:   $actual"
              exit 1
            fi
          '';
        };
      };
    };

    extraModprobeConfig = ''
      # PAT Support
      options nvidia NVreg_UsePageAttributeTable=1 NVreg_PreserveVideoMemoryAllocations=1
    '';

    # Use the Xanmod Kernel for gaming-related optimisations.
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
  };
}
