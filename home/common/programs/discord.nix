{
  inputs,
  ...
}:
{
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  # Docs: https://flameflag.github.io/nixcord/
  programs.nixcord = {
    enable = true;

    discord = {
      enable = true;
      krisp.enable = true;
      vencord.enable = true;
    };

    config = {
      plugins = {
        ClearURLs.enable = true;
        disableCallIdle.enable = true;

        fixCodeblockGap.enable = true;
        fixSpotifyEmbeds.enable = true;

        messageLogger.enable = true;
        MutualGroupDMs.enable = true;
        openInApp.enable = true;

        shikiCodeblocks.enable = true;
        sortFriendRequests.enable = true;

        translate.enable = true;
        validUser.enable = true;

        youtubeAdblock.enable = true;
      };
    };
  };
}
