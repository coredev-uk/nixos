{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  # Docs: https://kaylorben.github.io/nixcord/
  programs.nixcord = {
    enable = true;

    discord = {
      enable = true;
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
        AutoDNDWhilePlaying.enable = true;

        disableCallIdle.enable = true;

        fixCodeblockGap.enable = true;
        fixSpotifyEmbeds.enable = true;

        messageLogger.enable = true;
        openInApp.enable = true;

        shikiCodeblocks.enable = true;
        sortFriendRequests.enable = true;

        translate.enable = true;
        validUser.enable = true;

        youtubeAdblock.enable = true;
      };
    };
  };

  home.packages = [
    pkgs.discord-krisp-patcher
  ];

  home.activation.patchDiscordKrisp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "[patchDiscordKrisp] checking Discord Krisp modules"

    patch_missing_krisp() {
      base="$1"

      if [ ! -d "$base" ]; then
        echo "[patchDiscordKrisp] skip: $base does not exist"
        return 0
      fi

      for candidate in "$base"/*/modules/discord_krisp/discord_krisp.node; do
        [ -f "$candidate" ] || continue
        if [ -f "$candidate.orig" ]; then
          echo "[patchDiscordKrisp] skip: already patched $candidate"
          continue
        fi

        echo "[patchDiscordKrisp] patching: $candidate"
        ${pkgs.discord-krisp-patcher}/bin/krisp-patcher "$candidate" || true
      done
    }

    patch_missing_krisp "$HOME/.config/discord"
    patch_missing_krisp "$HOME/.config/discordcanary"
    patch_missing_krisp "$HOME/.config/discordptb"
  '';
}
