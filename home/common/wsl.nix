{ pkgs, meta, ... }:
{
  # The Windows Proton Pass app's SSH agent (\\.\pipe\openssh-ssh-agent) at the socket
  # home/common/shell/ssh.nix points ssh and git signing at. Socket-activated, one npiperelay.exe
  # per connection that exits with it: a Windows process left running (wsl2-ssh-agent's
  # powershell.exe) keeps WSL's VM up for good, holding memory the games want.
  systemd.user.sockets.proton-pass-agent = {
    Unit.Description = "Proton Pass's Windows SSH agent";
    Socket = {
      ListenStream = "${meta.homeDirectory}/.ssh/proton-pass-ssh-agent.sock";
      SocketMode = "0600";
      Accept = true;
    };
    Install.WantedBy = [ "sockets.target" ];
  };
  systemd.user.services."proton-pass-agent@" = {
    Unit.Description = "Relay to Proton Pass's Windows SSH agent";
    Service = {
      ExecStart = "${pkgs.npiperelay}/bin/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent";
      StandardInput = "socket";
    };
  };
}
