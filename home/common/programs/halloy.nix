_:
let
  nickname = "core";
in
{
  programs.halloy = {
    enable = true;

    # see: https://halloy.chat/configuration.html
    settings = {
      buffer = {
        server_messages.topic = {
          enabled = false;
        };
        server_messages.condense = {
          messages = [
            "join"
            "part"
            "quit"
          ];
          dimmed = true;
        };
      };

      servers = {
        liberachat = {
          nickname = "${nickname}-";
          channels = [
            "#halloy"
          ];
          server = "irc.libera.chat";
        };

        autobrr = {
          inherit nickname;
          channels = [
            "#chat"
          ];
          server = "irc.autobrr.com";
        };
      };
    };
  };

  catppuccin.halloy.enable = true;

}
