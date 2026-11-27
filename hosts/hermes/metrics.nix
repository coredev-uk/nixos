# Metrics for the cluster's Prometheus (home-ops o11y/hermes): node_exporter, plus what it can't
# see about a Pi on an SD card. Consumer SD cards report no wear level, so the signs of a failing
# card are filesystem and kernel errors, and how much is written to it.
{ pkgs, ... }:
let
  # tmpfs, so the metrics themselves don't write to the card.
  textfileDir = "/run/node-exporter-textfile";
in
{
  services.prometheus.exporters.node = {
    enable = true;
    extraFlags = [ "--collector.textfile.directory=${textfileDir}" ];
  };

  systemd.tmpfiles.rules = [ "d ${textfileDir} 0755 root root -" ];

  systemd.services.sd-card-metrics = {
    description = "SD card and power metrics for node_exporter";
    path = with pkgs; [
      coreutils
      gnugrep
      raspberrypi-utils
      systemd
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      fs=/sys/fs/ext4/mmcblk0p2
      card=/sys/block/mmcblk0/device
      # get_throttled: bit 0 under-voltage now, bit 16 under-voltage since boot.
      throttled=$(vcgencmd get_throttled | cut -d= -f2)
      kernel_errors=$(journalctl -k -b --no-pager -o cat | grep -c -E 'mmc0: .*(error|timeout)|mmcblk0.*I/O error' || true)
      tmp=$(mktemp ${textfileDir}/.sd-card.XXXXXX)
      cat >"$tmp" <<EOF
      # HELP sdcard_ext4_errors Errors the root filesystem has recorded since it was made.
      # TYPE sdcard_ext4_errors gauge
      sdcard_ext4_errors $(cat $fs/errors_count)
      # HELP sdcard_ext4_written_bytes_total Bytes written to the root filesystem since it was made.
      # TYPE sdcard_ext4_written_bytes_total counter
      sdcard_ext4_written_bytes_total $(( $(cat $fs/lifetime_write_kbytes) * 1024 ))
      # HELP sdcard_kernel_errors SD card errors in the kernel log since boot.
      # TYPE sdcard_kernel_errors gauge
      sdcard_kernel_errors $kernel_errors
      # HELP sdcard_info The SD card's identity.
      # TYPE sdcard_info gauge
      sdcard_info{name="$(cat $card/name)",manfid="$(cat $card/manfid)",oemid="$(cat $card/oemid)",date="$(cat $card/date)",serial="$(cat $card/serial)"} 1
      # HELP rpi_throttled_flags vcgencmd get_throttled.
      # TYPE rpi_throttled_flags gauge
      rpi_throttled_flags $(( throttled ))
      EOF
      chmod 0644 "$tmp"
      mv "$tmp" ${textfileDir}/sd-card.prom
    '';
  };

  systemd.timers.sd-card-metrics = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "5m";
    };
  };
}
