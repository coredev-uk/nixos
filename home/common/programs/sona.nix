{ inputs, pkgs, ... }:
{
  # Sona (github:coredev-uk/sona-go, its `nix` branch): the native Apple Music client. sona-nightly
  # is the newest published build, the nightly rc of main or the release when that is newer, with
  # the Last.fm and Discord credentials. It downloads the Widevine CDM from Google itself on first
  # start, into ~/.local/share/sona.
  home.packages = [ inputs.sona.packages.${pkgs.stdenv.hostPlatform.system}.sona-nightly ];
}
