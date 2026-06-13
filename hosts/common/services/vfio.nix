{
  config,
  lib,
  meta,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    escapeShellArg
    escapeShellArgs
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    optional
    optionalString
    optionals
    types
    ;

  cfg = config.services.vfioSingleGpu;
  userUid = toString config.users.users.${cfg.user}.uid;
  desktopItemName = "start-${cfg.vmName}-vfio";
  deviceAddresses = map (device: device.pciAddress) cfg.pciDevices;
  deviceAddressesShell = escapeShellArgs deviceAddresses;
  stopServicesShell = escapeShellArgs cfg.stopServices;
  restoreServicesShell = escapeShellArgs cfg.restoreServices;
  userProcessesWaitSeconds = toString cfg.userProcessesWaitSeconds;
  recoveryTimeoutSeconds = toString cfg.recoveryTimeoutSeconds;
  vbiosPath = "/run/libvirt/${cfg.vmName}-vfio/gpu.rom";
  desktopIcon = pkgs.stdenvNoCC.mkDerivation {
    pname = "${cfg.vmName}-desktop-icon";
    version = "1";
    src = ./assets/vfio-windows-11.png;
    dontUnpack = true;
    installPhase = ''
      install -Dm0644 "$src" "$out/share/icons/hicolor/256x256/apps/${cfg.desktopItem.icon}.png"
    '';
  };
  iommuKernelParams = [
    "iommu=pt"
  ]
  ++ optionals (cfg.iommu.cpuVendor == "amd") [ "amd_iommu=on" ]
  ++ optionals (cfg.iommu.cpuVendor == "intel") [ "intel_iommu=on" ];

  restoreDriverCases = concatMapStringsSep "\n" (
    device:
    optionalString (device.restoreDriver != null) ''
      ${escapeShellArg device.pciAddress})
        bind_to_driver "$dev" ${escapeShellArg device.restoreDriver}
        return
        ;;
    ''
  ) cfg.pciDevices;

  recoverVfio = pkgs.writeShellScript "${cfg.vmName}-vfio-recover" ''
    set -euo pipefail

    RESTORE_SERVICES=(${restoreServicesShell})
    DIAG_DIR="/var/log/libvirt/qemu/${cfg.vmName}-vfio-recovery"
    VIRSH="${pkgs.libvirt}/bin/virsh -c ${escapeShellArg cfg.libvirtUri}"

    ${pkgs.coreutils}/bin/mkdir -p "$DIAG_DIR"
    ${pkgs.coreutils}/bin/rm -f "$DIAG_DIR/screenshot.ppm"
    {
      printf 'recovery fired at %s\n' "$(${pkgs.coreutils}/bin/date --iso-8601=seconds)"
      $VIRSH domstate ${escapeShellArg cfg.vmName} || true
      $VIRSH domdisplay ${escapeShellArg cfg.vmName} || true
      $VIRSH domifaddr ${escapeShellArg cfg.vmName} || true
    } > "$DIAG_DIR/recovery.log" 2>&1

    $VIRSH dumpxml ${escapeShellArg cfg.vmName} > "$DIAG_DIR/domain.xml" 2>/dev/null || true
    $VIRSH screenshot ${escapeShellArg cfg.vmName} "$DIAG_DIR/screenshot.ppm" 2>>"$DIAG_DIR/recovery.log" || true

    $VIRSH destroy ${escapeShellArg cfg.vmName} || true

    if [ "''${#RESTORE_SERVICES[@]}" -gt 0 ]; then
      ${pkgs.systemd}/bin/systemctl start "''${RESTORE_SERVICES[@]}" || true
    fi
  '';

  launchVfio = pkgs.writeShellScript "${cfg.vmName}-vfio-launch" ''
    set -euo pipefail

    STOP_SERVICES=(${stopServicesShell})

    ${pkgs.systemd}/bin/systemctl stop ${escapeShellArg "${cfg.vmName}-vfio-recover.timer"} ${escapeShellArg "${cfg.vmName}-vfio-recover.service"} 2>/dev/null || true

    ${pkgs.systemd}/bin/systemd-run --unit=${escapeShellArg "${cfg.vmName}-vfio-recover"} --on-active=${recoveryTimeoutSeconds} \
      ${recoverVfio}

    if [ "''${#STOP_SERVICES[@]}" -gt 0 ]; then
      ${pkgs.systemd}/bin/systemctl stop "''${STOP_SERVICES[@]}" 2>/dev/null || true
    fi

    ${optionalString cfg.killUserSession ''
      ${pkgs.systemd}/bin/loginctl terminate-user ${escapeShellArg cfg.user} || true
      ${pkgs.systemd}/bin/systemctl stop --no-block ${escapeShellArg "user@${userUid}.service"} 2>/dev/null || true
      ${pkgs.systemd}/bin/loginctl kill-user ${escapeShellArg cfg.user} --signal=KILL || true
      ${pkgs.systemd}/bin/systemctl kill ${escapeShellArg "user@${userUid}.service"} --kill-whom=all --signal=KILL 2>/dev/null || true

      for _ in $(${pkgs.coreutils}/bin/seq 1 ${userProcessesWaitSeconds}); do
        if ! ${pkgs.procps}/bin/pgrep -u ${escapeShellArg cfg.user} >/dev/null; then
          break
        fi

        ${pkgs.coreutils}/bin/sleep 1
      done
    ''}

    ${pkgs.coreutils}/bin/sleep ${toString cfg.preStartDelaySeconds}
    ${pkgs.libvirt}/bin/virsh -c ${escapeShellArg cfg.libvirtUri} start ${escapeShellArg cfg.vmName}
  '';

  startVfio = pkgs.writeShellScriptBin desktopItemName ''
    set -euo pipefail

    SYSTEMD_RUN="${pkgs.systemd}/bin/systemd-run"
    VIRSH="${pkgs.libvirt}/bin/virsh"

    if [ "$($VIRSH -c ${escapeShellArg cfg.libvirtUri} domstate ${escapeShellArg cfg.vmName} 2>/dev/null || true)" = "running" ]; then
      exit 0
    fi

    "$SYSTEMD_RUN" --system --collect --unit=${escapeShellArg "${cfg.vmName}-vfio-start"} \
      ${launchVfio}
  '';

  startDesktopItem = pkgs.makeDesktopItem {
    name = cfg.desktopItem.name;
    desktopName = cfg.desktopItem.desktopName;
    comment = cfg.desktopItem.comment;
    exec = "${startVfio}/bin/${desktopItemName}";
    icon = cfg.desktopItem.icon;
    categories = cfg.desktopItem.categories;
    terminal = false;
  };

  gpuHook = pkgs.writeShellScript "${cfg.vmName}-vfio-hook" ''
    set -euo pipefail

    VM_NAME="''${1:-}"
    OPERATION="''${2:-}"
    SUB_OPERATION="''${3:-}"
    DOMAIN_XML="$(${pkgs.coreutils}/bin/cat)"
    STATE_DIR="/run/libvirt/${cfg.vmName}-vfio"
    STATE_FILE="$STATE_DIR/active"
    LOG_FILE="/run/libvirt/${cfg.vmName}-vfio-hook.log"
    DEVICES=(${deviceAddressesShell})
    STOP_SERVICES=(${stopServicesShell})
    RESTORE_SERVICES=(${restoreServicesShell})

    log() {
      printf '${cfg.vmName}-vfio-hook: %s\n' "$*" >&2
      printf '%s %s\n' "$(${pkgs.coreutils}/bin/date --iso-8601=seconds)" "$*" >> "$LOG_FILE" || true
      printf '%s\n' "$*" | ${pkgs.systemd}/bin/systemd-cat -t ${escapeShellArg "${cfg.vmName}-vfio-hook"} -p info || true
    }

    unbind_if_bound() {
      local dev="$1"

      if [ -e "/sys/bus/pci/devices/$dev/driver/unbind" ]; then
        echo "$dev" > "/sys/bus/pci/devices/$dev/driver/unbind"
      fi
    }

    bind_to_driver() {
      local dev="$1"
      local driver="$2"

      if [ -d "/sys/bus/pci/drivers/$driver" ]; then
        echo "$dev" > "/sys/bus/pci/drivers/$driver/bind" || true
      fi
    }

    discover_devices() {
      mapfile -t DEVICES < <(
        printf '%s' "$DOMAIN_XML" | CONFIGURED_DEVICES="${lib.concatStringsSep " " deviceAddresses}" ${pkgs.python3}/bin/python3 -c '
    import os
    import sys
    import xml.etree.ElementTree as ET

    configured = []
    for device in os.environ["CONFIGURED_DEVICES"].split():
        domain, bus, slot_function = device.split(":")
        slot, function = slot_function.split(".")
        configured.append(tuple(int(part, 16) for part in (domain, bus, slot, function)))

    try:
        root = ET.fromstring(sys.stdin.read())
    except ET.ParseError:
        sys.exit(1)

    hostdevs = []
    for hostdev in root.findall(".//hostdev"):
        if hostdev.get("mode") != "subsystem" or hostdev.get("type") != "pci":
            continue

        address = hostdev.find("./source/address")
        if address is None:
            continue

        pci = tuple(int(address.get(field), 0) for field in ("domain", "bus", "slot", "function"))
        hostdevs.append(pci)

    selected = configured or hostdevs
    for pci in selected:
        if pci in hostdevs:
            print(f"{pci[0]:04x}:{pci[1]:02x}:{pci[2]:02x}.{pci[3]:x}")

    sys.exit(0)
        '
      )

      [ "''${#DEVICES[@]}" -gt 0 ]
    }

    cancel_recovery() {
      ${pkgs.systemd}/bin/systemctl stop ${escapeShellArg "${cfg.vmName}-vfio-recover.timer"} ${escapeShellArg "${cfg.vmName}-vfio-recover.service"} 2>/dev/null || true
    }

    stop_graphics() {
      log "stopping services using the passthrough GPU"

      if [ "''${#STOP_SERVICES[@]}" -gt 0 ]; then
        ${pkgs.systemd}/bin/systemctl stop "''${STOP_SERVICES[@]}" 2>/dev/null || true
      fi

      ${optionalString cfg.killUserSession ''
        ${pkgs.systemd}/bin/loginctl terminate-user ${escapeShellArg cfg.user} || true
        ${pkgs.systemd}/bin/systemctl stop --no-block ${escapeShellArg "user@${userUid}.service"} 2>/dev/null || true

        log "force-killing ${cfg.user} processes"
        ${pkgs.systemd}/bin/loginctl kill-user ${escapeShellArg cfg.user} --signal=KILL || true
        ${pkgs.systemd}/bin/systemctl kill ${escapeShellArg "user@${userUid}.service"} --kill-whom=all --signal=KILL 2>/dev/null || true

        for _ in $(${pkgs.coreutils}/bin/seq 1 ${userProcessesWaitSeconds}); do
          if ! ${pkgs.procps}/bin/pgrep -u ${escapeShellArg cfg.user} >/dev/null; then
            break
          fi

          ${pkgs.coreutils}/bin/sleep 1
        done
      ''}

      ${pkgs.coreutils}/bin/sleep 1
    }

    unbind_framebuffers() {
      log "unbinding host framebuffers"
      ${pkgs.coreutils}/bin/mkdir -p "$STATE_DIR"

      for vtcon in /sys/class/vtconsole/vtcon*; do
        if [ -e "$vtcon/bind" ]; then
          echo 0 > "$vtcon/bind" || true
        fi
      done

      : > "$STATE_DIR/framebuffers"
      for driver in efi-framebuffer simple-framebuffer vesa-framebuffer; do
        if [ ! -e "/sys/bus/platform/drivers/$driver/unbind" ]; then
          continue
        fi

        for device in /sys/bus/platform/drivers/$driver/*; do
          if [ -e "$device/driver" ]; then
            device_name="$(${pkgs.coreutils}/bin/basename "$device")"
            log "unbinding platform framebuffer $driver/$device_name"
            printf '%s %s\n' "$driver" "$device_name" >> "$STATE_DIR/framebuffers"
            printf '%s\n' "$device_name" > "/sys/bus/platform/drivers/$driver/unbind" 2>/dev/null || true
          fi
        done
      done
    }

    bind_framebuffers() {
      log "rebinding host framebuffers"

      if [ -e "$STATE_DIR/framebuffers" ]; then
        while read -r driver device_name; do
          if [ -n "$driver" ] && [ -n "$device_name" ] && [ -e "/sys/bus/platform/drivers/$driver/bind" ]; then
            printf '%s\n' "$device_name" > "/sys/bus/platform/drivers/$driver/bind" 2>/dev/null || true
          fi
        done < "$STATE_DIR/framebuffers"
      fi

      for vtcon in /sys/class/vtconsole/vtcon*; do
        if [ -e "$vtcon/bind" ]; then
          printf '%s\n' 1 > "$vtcon/bind" 2>/dev/null || true
        fi
      done
    }

    dump_vbios() {
      local gpu="''${DEVICES[0]:-}"
      local rom_path=${escapeShellArg vbiosPath}
      local sysfs_rom=""

      if [ ${lib.boolToString cfg.vbios.dump} != true ]; then
        return 0
      fi

      if [ -z "$gpu" ]; then
        log "cannot dump VBIOS because no GPU hostdev was discovered"
        return 1
      fi

      sysfs_rom="/sys/bus/pci/devices/$gpu/rom"
      if [ ! -e "$sysfs_rom" ]; then
        log "no VBIOS ROM sysfs node for $gpu"
        return 1
      fi

      log "dumping $gpu VBIOS to $rom_path"
      ${pkgs.coreutils}/bin/rm -f "$rom_path"
      echo 1 > "$sysfs_rom" || true
      if ! ${pkgs.coreutils}/bin/cp "$sysfs_rom" "$rom_path" 2>/dev/null; then
        log "failed to dump $gpu VBIOS"
        ${pkgs.coreutils}/bin/rm -f "$rom_path"
        echo 0 > "$sysfs_rom" || true
        return 1
      fi

      if [ ! -s "$rom_path" ]; then
        log "dumped VBIOS is empty"
        ${pkgs.coreutils}/bin/rm -f "$rom_path"
        echo 0 > "$sysfs_rom" || true
        return 1
      fi

      echo 0 > "$sysfs_rom" || true
      ${pkgs.coreutils}/bin/chmod 0644 "$rom_path" 2>/dev/null || true
      log "dumped $gpu VBIOS to $rom_path ($(${pkgs.coreutils}/bin/stat -c %s "$rom_path") bytes)"
    }

    unload_modules() {
      log "unloading host GPU modules"

      for module in ${escapeShellArgs cfg.unloadModules}; do
        ${pkgs.kmod}/bin/modprobe -r "$module" 2>/dev/null || true
      done

      for module in ${escapeShellArgs cfg.assertUnloadedModules}; do
        if ${pkgs.gnugrep}/bin/grep -q "^$module" /proc/modules; then
          log "$module is still in use; aborting passthrough start"
          return 1
        fi
      done
    }

    load_modules() {
      log "loading host GPU modules"

      for module in ${escapeShellArgs cfg.reloadModules}; do
        ${pkgs.kmod}/bin/modprobe "$module" 2>/dev/null || true
      done
    }

    restore_device_driver() {
      local dev="$1"
      local driver=""

      case "$dev" in
    ${restoreDriverCases}
      esac

      if [ -e "$STATE_DIR/$dev.driver" ]; then
        driver="$(${pkgs.coreutils}/bin/cat "$STATE_DIR/$dev.driver")"
      fi

      if [ -n "$driver" ]; then
        bind_to_driver "$dev" "$driver"
      fi
    }

    start_passthrough() {
      trap 'log "passthrough start failed; restoring host GPU"; stop_passthrough force' ERR

      stop_graphics
      unbind_framebuffers
      unload_modules
      ${pkgs.coreutils}/bin/mkdir -p "$STATE_DIR"
      dump_vbios

      log "loading vfio-pci"
      ${pkgs.kmod}/bin/modprobe vfio-pci
      printf '%s\n' "''${DEVICES[@]}" > "$STATE_DIR/devices"

      for dev in "''${DEVICES[@]}"; do
        log "binding $dev to vfio-pci"

        if [ -e "/sys/bus/pci/devices/$dev/driver" ]; then
          ${pkgs.coreutils}/bin/basename "$(${pkgs.coreutils}/bin/readlink -f "/sys/bus/pci/devices/$dev/driver")" > "$STATE_DIR/$dev.driver"
        fi

        echo vfio-pci > "/sys/bus/pci/devices/$dev/driver_override"
        unbind_if_bound "$dev"
        echo "$dev" > /sys/bus/pci/drivers/vfio-pci/bind
        log "$dev driver is $(${pkgs.coreutils}/bin/basename "$(${pkgs.coreutils}/bin/readlink -f "/sys/bus/pci/devices/$dev/driver")")"
      done

      ${pkgs.coreutils}/bin/touch "$STATE_FILE"
      trap - ERR
    }

    stop_passthrough() {
      local force="''${1:-}"

      if [ ! -e "$STATE_FILE" ] && [ "$force" != "force" ]; then
        exit 0
      fi

      if [ "''${#DEVICES[@]}" -eq 0 ] && [ -e "$STATE_DIR/devices" ]; then
        mapfile -t DEVICES < "$STATE_DIR/devices"
      fi

      for dev in "''${DEVICES[@]}"; do
        if [ -e "/sys/bus/pci/devices/$dev/driver" ] && [ "$(${pkgs.coreutils}/bin/basename "$(${pkgs.coreutils}/bin/readlink -f "/sys/bus/pci/devices/$dev/driver")")" = "vfio-pci" ]; then
          log "unbinding $dev from vfio-pci"
          unbind_if_bound "$dev"
        fi

        echo "" > "/sys/bus/pci/devices/$dev/driver_override"
      done

      load_modules

      for dev in "''${DEVICES[@]}"; do
        restore_device_driver "$dev"
      done

      bind_framebuffers

      if [ "''${#RESTORE_SERVICES[@]}" -gt 0 ]; then
        log "starting services after passthrough"
        ${pkgs.systemd}/bin/systemctl start "''${RESTORE_SERVICES[@]}" || true
      fi

      ${pkgs.coreutils}/bin/rm -f "$STATE_FILE"
      ${pkgs.coreutils}/bin/rm -f "$STATE_DIR/devices"
      ${pkgs.coreutils}/bin/rm -f "$STATE_DIR"/*.driver 2>/dev/null || true
    }

    if [ "$VM_NAME" != ${escapeShellArg cfg.vmName} ]; then
      exit 0
    fi

    case "$OPERATION:$SUB_OPERATION" in
      prepare:begin)
        if ! discover_devices; then
          log "${cfg.vmName} has no matching PCI hostdevs; skipping passthrough"
          exit 0
        fi

        start_passthrough
        ;;
      started:begin)
        ${optionalString cfg.cancelRecoveryOnStarted "cancel_recovery"}
        ;;
      release:end)
        cancel_recovery
        discover_devices || true
        stop_passthrough
        ;;
    esac
  '';
in
{
  options.services.vfioSingleGpu = {
    enable = mkEnableOption "single-GPU VFIO passthrough support for a libvirt VM";

    vmName = mkOption {
      type = types.str;
      default = "win11";
      description = "Name of the libvirt domain that receives the GPU.";
    };

    libvirtUri = mkOption {
      type = types.str;
      default = "qemu:///system";
      description = "Libvirt connection URI used by helper scripts.";
    };

    user = mkOption {
      type = types.str;
      default = meta.username;
      defaultText = literalExpression "meta.username";
      description = "User whose graphical session is stopped before single-GPU passthrough.";
    };

    pciDevices = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            pciAddress = mkOption {
              type = types.strMatching "[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\\.[0-7]";
              example = "0000:08:00.0";
              description = "Host PCI address to bind to vfio-pci while the VM is running.";
            };

            restoreDriver = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "nvidia";
              description = "Driver to bind this PCI device back to after the VM stops.";
            };
          };
        }
      );
      default = [ ];
      example = literalExpression ''
        [
          { pciAddress = "0000:08:00.0"; restoreDriver = "nvidia"; }
          { pciAddress = "0000:08:00.1"; restoreDriver = "snd_hda_intel"; }
        ]
      '';
      description = "Optional explicit passthrough PCI devices. If empty, the libvirt hook discovers PCI hostdevs from the VM XML at startup and restores their original host drivers afterwards.";
    };

    stopServices = mkOption {
      type = types.listOf types.str;
      default = optional config.services.greetd.enable "greetd.service";
      defaultText = literalExpression ''lib.optional config.services.greetd.enable "greetd.service"'';
      description = "System services to stop before the GPU is detached from the host.";
    };

    restoreServices = mkOption {
      type = types.listOf types.str;
      default = cfg.stopServices;
      defaultText = literalExpression "config.services.vfioSingleGpu.stopServices";
      description = "System services to start after the GPU is returned to the host.";
    };

    killUserSession = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to terminate the configured user's session before GPU detach.";
    };

    userProcessesWaitSeconds = mkOption {
      type = types.ints.positive;
      default = 20;
      description = "Maximum time to wait for user processes to exit before starting the VM.";
    };

    preStartDelaySeconds = mkOption {
      type = types.ints.unsigned;
      default = 2;
      description = "Delay after stopping host graphics and before starting the VM.";
    };

    recoveryTimeoutSeconds = mkOption {
      type = types.ints.positive;
      default = 300;
      description = "Safety timeout that destroys the VM and restarts host graphics if startup does not complete.";
    };

    cancelRecoveryOnStarted = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to cancel the safety recovery timer as soon as QEMU starts. Disable while debugging black-screen startup failures.";
    };

    lookingGlassMemoryMb = mkOption {
      type = types.ints.positive;
      default = 64;
      description = "Static kvmfr shared-memory size for Looking Glass.";
    };

    vbios = {
      dump = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to dump the boot GPU VBIOS before detaching it for use by the VM.";
      };

      path = mkOption {
        type = types.str;
        readOnly = true;
        default = vbiosPath;
        description = "Runtime path where the dumped VBIOS is written for libvirt's rom file attribute.";
      };
    };

    iommu = {
      enableKernelParams = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to add common host kernel parameters needed for VFIO passthrough.";
      };

      cpuVendor = mkOption {
        type = types.enum [
          "amd"
          "intel"
        ];
        example = "amd";
        description = "CPU vendor used to select the correct IOMMU kernel parameter.";
      };
    };

    unloadModules = mkOption {
      type = types.listOf types.str;
      default = [
        "snd_hda_intel"
        "nvidia_drm"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia"
      ];
      description = "Kernel modules to unload before binding passthrough devices to vfio-pci.";
    };

    assertUnloadedModules = mkOption {
      type = types.listOf types.str;
      default = [ "nvidia" ];
      description = "Modules that must be absent after unloading, otherwise VM startup is aborted.";
    };

    reloadModules = mkOption {
      type = types.listOf types.str;
      default = [
        "nvidia"
        "nvidia_uvm"
        "nvidia_modeset"
        "nvidia_drm"
        "snd_hda_intel"
      ];
      description = "Kernel modules to reload after the VM stops.";
    };

    desktopItem = {
      name = mkOption {
        type = types.str;
        default = cfg.vmName;
        description = "Desktop file id for the VM launcher.";
      };

      desktopName = mkOption {
        type = types.str;
        default = cfg.vmName;
        description = "Display name for the VM launcher.";
      };

      comment = mkOption {
        type = types.str;
        default = "Start ${cfg.vmName} with single-GPU passthrough";
        description = "Comment shown by desktop launchers.";
      };

      icon = mkOption {
        type = types.str;
        default = "computer";
        description = "Icon name for the VM launcher.";
      };

      categories = mkOption {
        type = types.listOf types.str;
        default = [ "System" ];
        description = "Desktop menu categories for the VM launcher.";
      };
    };
  };

  config = mkIf cfg.enable {
    boot.kernelModules = [
      "kvmfr"
      "vfio"
      "vfio-pci"
      "vfio_iommu_type1"
    ];

    boot.extraModulePackages = [ config.boot.kernelPackages.kvmfr ];
    boot.kernelParams = optionals cfg.iommu.enableKernelParams iommuKernelParams ++ [
      "kvmfr.static_size_mb=${toString cfg.lookingGlassMemoryMb}"
    ];

    services.udev.packages = lib.singleton (
      pkgs.writeTextFile {
        name = "kvmfr-udev-rules";
        destination = "/etc/udev/rules.d/70-kvmfr.rules";
        text = ''
          SUBSYSTEM=="kvmfr", GROUP="kvm", MODE="0660", TAG+="uaccess"
        '';
      }
    );

    environment.systemPackages = with pkgs; [
      desktopIcon
      looking-glass-client
      qemu_kvm
      startDesktopItem
      startVfio
      swtpm
      virt-manager
      virt-viewer
    ];

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == ${builtins.toJSON cfg.user} &&
            action.lookup("unit") == ${builtins.toJSON "${cfg.vmName}-vfio-start.service"} &&
            action.lookup("verb") == "start") {
          return polkit.Result.YES;
        }
      });
    '';

    system.activationScripts.libvirtImagesNoCow.text = ''
      imagesDir=/var/lib/libvirt/images
      ${pkgs.coreutils}/bin/mkdir -p "$imagesDir"

      # Btrfs NOCOW must be set before VM image files are created.
      if [ -z "$(${pkgs.coreutils}/bin/ls -A "$imagesDir")" ]; then
        ${pkgs.e2fsprogs}/bin/chattr +C "$imagesDir" 2>/dev/null || true
      fi
    '';

    programs.virt-manager.enable = true;

    users.users.${cfg.user}.extraGroups = [
      "kvm"
      "libvirtd"
    ];

    virtualisation.libvirtd = {
      enable = true;

      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
        verbatimConfig = ''
          namespaces = []
          cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm",
            "/dev/rtc", "/dev/hpet", "/dev/vfio/vfio",
            "/dev/kvmfr0"
          ]
        '';
      };

      hooks.qemu."10-${cfg.vmName}-vfio" = gpuHook;
    };
  };
}
