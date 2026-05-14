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
      openASAR.enable = true;
      vencord = {
        enable = true;
        unstable = false;
      };
    };

    config = {
      useQuickCss = true;
      themeLinks = [
        "https://luckfire.github.io/amoled-cord/src/amoled-cord.css"
      ];

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
