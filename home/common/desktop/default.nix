{
  inputs,
  pkgs,
  meta,
  self,
  ...
}:
{

  age.secrets.proton_username.file = "${self}/secrets/proton_username.age";
  age.secrets.proton_password.file = "${self}/secrets/proton_password.age";

  imports = [
    (./. + "/${meta.desktop}")

    # Environment Configurations
    ./default/gtk.nix
    ./default/qt.nix
    ./default/xdg.nix

    ../scripts

    # Standard Programs
    ../programs/discord.nix
    ../programs/element.nix
    ../programs/gaming.nix
    ../programs/ghostty.nix
    ../programs/halloy.nix
    ../programs/zen.nix
    # ./programs/rclone.nix
  ];

  home.packages = with pkgs; [
    brave
    catppuccin-gtk
    cider-2
    desktop-file-utils
    file-roller
    jellyfin-desktop
    loupe
    mpv
    inputs.moonfin-flake.packages.${meta.system}.default
    nautilus
    proton-vpn-cli
    papers
    spotify
    teamspeak6-client
  ];

}
