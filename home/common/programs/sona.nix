{ inputs, pkgs, ... }:
{
  # Sona (github:coredev-uk/sona-go): the native Apple Music client, built from its flake. It
  # downloads the Widevine CDM from Google itself on first start, into ~/.local/share/sona.
  home.packages = [ inputs.sona.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
