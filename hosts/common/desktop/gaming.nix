{
  pkgs,
  inputs,
  unstable,
  ...
}:
let
  nix-citizen = inputs.nix-citizen.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    inputs.nix-citizen.nixosModules.default
  ];

  programs = {
    # Star Citizen, via the RSI Launcher (src: https://github.com/LovingMelody/nix-citizen)
    rsi-launcher = {
      enable = true;
      location = "$HOME/games/star-citizen";
      # The default overlay rebuilds wine-astral, dxvk and a mingw cross GCC against our
      # nixpkgs (hours, uncached). nix-citizen's own packages, built against its pinned
      # nixpkgs, are prebuilt in nix-citizen.cachix.org. Set explicitly: the module's
      # no-overlay fallback indexes `self.packages` by the platform set, not its system
      # string, and fails to evaluate.
      includeOverlay = false;
      package = nix-citizen.rsi-launcher;
      wine = nix-citizen.wine-astral;
    };

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
      # From unstable: GE-Proton releases far more often than 26.05 picks them up.
      extraCompatPackages = [
        unstable.proton-ge-bin
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

  # Required for Esync (https://github.com/lutris/docs/blob/master/HowToEsync.md)
  systemd.settings.Manager = {
    DefaultLimitNOFILE = 524288;
  };
}
