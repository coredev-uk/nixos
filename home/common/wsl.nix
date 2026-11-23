{ pkgs, meta, ... }:
{
  # Windows Proton Pass SSH agent at the socket shell/ssh.nix uses. Socket-activated with one
  # npiperelay.exe per connection: a lingering Windows process (wsl2-ssh-agent) keeps the WSL VM up.
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
