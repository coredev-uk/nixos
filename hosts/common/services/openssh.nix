{ meta, ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      # UsePAM stays on, so PAM's keyboard-interactive would still take the account password.
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ meta.username ];
    };
  };
}
