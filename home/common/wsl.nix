{ pkgs, meta, ... }:
{
  # The Windows Proton Pass app's SSH agent (\\.\pipe\openssh-ssh-agent) at the socket
  # home/common/shell/ssh.nix points ssh and git signing at. wsl2-ssh-agent relays each request
  # through one long-running powershell.exe, so it needs WSL interop.
  systemd.user.services.wsl2-ssh-agent = {
    Unit.Description = "Bridge to the Windows SSH agent (Proton Pass)";
    Service = {
      ExecStart = "${pkgs.wsl2-ssh-agent}/bin/wsl2-ssh-agent -foreground -socket ${meta.homeDirectory}/.ssh/proton-pass-ssh-agent.sock -powershell-path /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
