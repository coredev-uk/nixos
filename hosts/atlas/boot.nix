{
  config,
  pkgs,
  lib,
  modulesPath,
  meta,
  ...
}:
let
  # Enroll TPM2 (keep a working LUKS passphrase before wiping slots):
  #   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7+12 --wipe-slot=tpm2 /dev/sdX
  # PCR15 value from `systemd-analyze pcrs 15 --json=short` after one boot with tpm2-measure-pcr;
  # null skips the check (initrd refuses to boot on a wrong value).
  expectedPcr15 = "a701700021416549c66fdb8693a771a159f78fde232e5aa3aca4d3c23f268ef9";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    ../common/base
    ../common/users/${meta.username}
  ];

  # Never bump (gates stateful migrations).
  system.stateVersion = "26.05";

  environment.systemPackages = with pkgs; [
    efibootmgr
  ];

  boot = {
    loader.systemd-boot.enable = lib.mkForce false; # lanzaboote replaces it
    loader.timeout = 1;
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
      # Bounds generations on the 1 GiB ESP.
      configurationLimit = 10;
      # 3 boot attempts, then systemd-boot falls back to the previous generation.
      bootCounting.initialTries = 3;
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

    # Gaming-tuned kernel.
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
  };
}
