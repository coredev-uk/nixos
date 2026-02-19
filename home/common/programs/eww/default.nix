{ pkgs, ... }:
{
  programs.eww = {
    enable = true;

    configDir = ./config;
    enableZshIntegration = true;
  };

  # Needed for scripts
  home.packages = with pkgs; [
    jq
    socat
    ffmpeg
  ];

  systemd.user.services.eww = {
    Unit = {
      Description = "ElKowars wacky widgets daemon";
      PartOf = [ "graphical-session.target" ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
      Restart = "on-failure";
    };
  };
}
