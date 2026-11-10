{ config, lib, ... }:
{
  xdg = {
    enable = true;

    configHome = config.home.homeDirectory + "/.config";
    cacheHome = config.home.homeDirectory + "/.local/cache";
    dataHome = config.home.homeDirectory + "/.local/share";
    stateHome = config.home.homeDirectory + "/.local/state";

    userDirs = {
      enable = true;

      setSessionVariables = false;

      createDirectories = lib.mkDefault true;

      download = config.home.homeDirectory + "/downloads";
      pictures = config.home.homeDirectory + "/pictures";

      desktop = config.home.homeDirectory;
      documents = config.home.homeDirectory;
      music = config.home.homeDirectory;
      publicShare = config.home.homeDirectory;
      templates = config.home.homeDirectory;
      videos = config.home.homeDirectory;

      extraConfig = {
        SCREENSHOTS = "${config.home.homeDirectory}/pictures/screenshots";
        # The shell's screen recorder (home/common/programs/quickshell/config/services/Recorder.qml).
        RECORDINGS = "${config.home.homeDirectory}/videos/recordings";
      };
    };
  };
}
