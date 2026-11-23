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
    # Star Citizen (https://github.com/LovingMelody/nix-citizen)
    rsi-launcher = {
      enable = true;
      location = "$HOME/games/star-citizen";
      # Default overlay rebuilds wine-astral, dxvk and mingw GCC against our nixpkgs (hours,
      # uncached); nix-citizen's own packages are in its cachix. Explicit because the module's
      # no-overlay fallback indexes `self.packages` wrongly and fails to evaluate.
      includeOverlay = false;
      package = nix-citizen.rsi-launcher;
      wine = nix-citizen.wine-astral;
    };

    steam = {
      enable = true;

      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;

      protontricks = {
        enable = true;
      };

      # From unstable: GE-Proton releases faster than 26.05.
      extraCompatPackages = [
        unstable.proton-ge-bin
      ];

      package = pkgs.steam.override {
        extraPkgs = pkgs: [
          pkgs.corefonts
        ];
      };
    };

    # The user needs the gamemode group (users/paul): polkit only lets it change governor/GPU/procsys.
    gamemode = {
      enable = true;
      settings.general = {
        renice = 10;
        softrealtime = "auto";
      };
    };

    gamescope.enable = true;
  };

  # Open-file limit for every unit, so the uwsm session too (Esync); systemd's default soft is 1024.
  systemd.settings.Manager = {
    DefaultLimitNOFILE = 524288;
  };
}
