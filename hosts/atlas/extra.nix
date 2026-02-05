{
  self,
  lib,
  pkgs,
  meta,
  ...
}:
let
  bootwin = pkgs.writeScriptBin "bootwin" ''
    #!/bin/sh
    sudo su - <<EOF
    efibootmgr -n 0000
    reboot
    EOF
  '';
in
{
  imports = [
    "${self}/hosts/common/services/networkmanager.nix"
    "${self}/hosts/common/desktop/gaming.nix"
    "${self}/hosts/common/desktop/rgb.nix"
    "${self}/hosts/common/desktop/qmk.nix"
    "${self}/hosts/common/desktop/ddcci-driver.nix"
    "${self}/hosts/common/desktop/dev.nix"
    "${self}/hosts/common/base/nix-ld.nix"
  ]
  ++ lib.optional (meta.desktop == "i3") ./display.nix;

  # Add bootwin script to reboot into Windows
  environment.systemPackages = [
    bootwin
  ];

  # DNS
  networking.nameservers = [
    "192.168.20.20"
    "192.168.10.1"
  ];

  # Enforce Static DNS
  networking.networkmanager.dns = "none";

  # Disable suspend of Toslink output to prevent audio popping.
  services.pipewire.wireplumber.extraConfig."99-disable-suspend" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {
            "node.name" = "alsa_output.usb-Generic_ATH-M50xSTS-USB-00.analog-stereo";
          }
        ];
        actions = {
          update-props = {
            "session.suspend-timeout-seconds" = 0;
          };
        };
      }
    ];
  };
}
