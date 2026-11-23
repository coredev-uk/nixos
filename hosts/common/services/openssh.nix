{ meta, ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      # UsePAM is on: this stops PAM's keyboard-interactive taking the password.
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ meta.username ];
    };
  };
}
