{
  inputs,
  pkgs,
  self,
  ...
}:
let
  inherit (import "${self}/lib/theme" { inherit pkgs; }) catppuccin;
  # catppuccin/discord's published build tracks Discord's class-name changes, so load it
  # online (as catppuccin/nix does for Vesktop). nixcord only writes local theme files
  # for Vesktop/Equibop, so a theme link is the way to reach Discord + Vencord.
  themeUrl = "https://catppuccin.github.io/discord/dist/catppuccin-${catppuccin.flavor}-${catppuccin.accent}.theme.css";
in
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
      themeLinks = [ themeUrl ];
      plugins = {
        clearUrls.enable = true;
        disableCallIdle.enable = true;

        fixCodeblockGap.enable = true;
        fixSpotifyEmbeds.enable = true;

        messageLogger.enable = true;
        mutualGroupDms.enable = true;
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
