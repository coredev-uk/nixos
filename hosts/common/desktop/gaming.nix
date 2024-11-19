{ pkgs, inputs, ... }:
{
  # Enable Steam
  programs.steam = {
    enable = true;

    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    # dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers

    # Protontricks
    protontricks = {
      enable = true;
    };

    # Proton-GE
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # Enable GameMode
  programs.gamemode = {
    enable = true;

    settings = {
      custom = {
        start = "killall picom";
        end = "if not pgrep picom && not pgrep Hyprland; then exec picom; fi";
      };
    };
  };

  # Enable Mangohud and Lutris
  environment.systemPackages = with pkgs; [
    mangohud
    lutris

    # nix-gaming packages
    inputs.nix-gaming.packages.${pkgs.system}.star-citizen
    inputs.nix-gaming.packages.${pkgs.system}.wine-ge
  ];

  # Tweaks Required for Star-Citizen (https://github.com/fufexan/nix-gaming/tree/master/pkgs/star-citizen)
  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
    "fs.file-max" = 524288;
  };
}
