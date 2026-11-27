{
  lib,
  meta,
  pkgs,
  ...
}:
let
  # Home Assistant's address on the IoT VLAN (home-ops: kubernetes/apps/default/home-assistant).
  homeAssistant = "192.168.130.20";
  stateDir = "/var/lib/btproxy";
in
{
  imports = [ ../common/services/auto-upgrade.nix ];

  # Key-only SSH (common/services/openssh.nix) and no password set for the user.
  security.sudo.wheelNeedsPassword = false;

  # zsh is the login shell, and no Home Manager writes its rc here: an empty one keeps
  # zsh-newuser-install's menu off every SSH login.
  systemd.tmpfiles.rules = [ "f ${meta.homeDirectory}/.zshrc 0644 ${meta.username} users -" ];

  # Bluetooth proxy for Home Assistant, which adds it through the ESPHome integration (port 6053,
  # found over mDNS). Kernel backend: btproxy drives the adapter itself, so no BlueZ/bluetoothd.
  # Hardening follows upstream's unit (contrib/systemd/btproxy.service): root for the Bluetooth
  # management socket and CAP_NET_RAW, the rest taken away.
  systemd.services.btproxy = {
    description = "btproxy, ESPHome-compatible Bluetooth proxy";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    # The API encryption key, made once on the host and kept out of Git; Home Assistant asks for it
    # when the proxy is added: `sudo cat /var/lib/btproxy/api.key`.
    preStart = ''
      if [ ! -s ${stateDir}/api.key ]; then
        (umask 077; head -c 32 /dev/urandom | base64 > ${stateDir}/api.key)
      fi
    '';

    serviceConfig = {
      ExecStart = lib.escapeShellArgs [
        (lib.getExe pkgs.btproxy)
        "-name"
        "hermes"
        "-friendly-name"
        "Hermes"
        "-backend"
        "kernel"
        "-bond-dir"
        "${stateDir}/bonds"
        "-encryption-key-file"
        "${stateDir}/api.key"
      ];
      Restart = "always";
      RestartSec = 5;

      # Bonded devices' keys and the API key.
      StateDirectory = [
        "btproxy"
        "btproxy/bonds"
      ];
      StateDirectoryMode = "0700";

      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
      # AF_NETLINK: network interfaces, for mDNS. AF_BLUETOOTH: the adapter and the HCI monitor.
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
        "AF_BLUETOOTH"
      ];
    };
  };

  networking.firewall = {
    # btproxy's mDNS answers, for Home Assistant's discovery.
    allowedUDPPorts = [ 5353 ];
    # The API (6053) for Home Assistant only; the rest of the IoT VLAN can't reach it.
    extraCommands = ''
      iptables -A nixos-fw -p tcp -s ${homeAssistant} --dport 6053 -j nixos-fw-accept
    '';
  };
}
