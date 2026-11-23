# Follows main each morning (or at the next boot if off). Main only gets changes after Hosts CI
# cached the host in Attic, so the switch just downloads. Local-checkout switches revert.
{ pkgs, meta, ... }:
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:coredev-uk/nixos#${meta.hostname}";
    upgrade = false; # flakes, no channels
    dates = "05:00";
    randomizedDelaySec = "30min";
  };

  # Notify the user what changed (home/common/auto-upgrade); fails quietly if they're logged out,
  # and the next home upgrade reports it instead.
  systemd.services.nixos-upgrade.serviceConfig.ExecStopPost =
    "-${pkgs.writeShellScript "nixos-upgrade-report" ''
      ${pkgs.systemd}/bin/systemctl --user -M ${meta.username}@ --no-block \
        start "upgrade-report@system-$SERVICE_RESULT.service"
    ''}";
}
