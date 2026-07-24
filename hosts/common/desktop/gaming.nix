{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nix-citizen.nixosModules.default
  ];

  programs = {
    # Star Citizen, via the RSI Launcher (src: https://github.com/LovingMelody/nix-citizen)
    rsi-launcher.enable = true;

    # Enable Steam
    steam = {
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

      package = pkgs.steam.override {
        extraPkgs = pkgs: [
          pkgs.corefonts # Microsoft Core Fonts
        ];
      };
    };

    # Enable GameMode
    gamemode = {
      enable = true;
    };

    # gamescope
    gamescope.enable = true;
  };

  # For Epic Games Store in Lutris
  hardware.graphics.enable32Bit = true;

  # Required for Esync (https://github.com/lutris/docs/blob/master/HowToEsync.md)
  systemd.settings.Manager = {
    DefaultLimitNOFILE = 524288;
  };
}
