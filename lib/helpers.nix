{
  self,
  inputs,
  outputs,
  stateVersion,
  username,
  flakePath,
  ...
}:
{
  # Helper function for generating home-manager configs
  mkHome =
    {
      hostname,
      user ? username,
      desktop ? null,
      system ? "x86_64-linux",
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.unstable.legacyPackages.${system};
      extraSpecialArgs = {
        stable = inputs.nixpkgs.legacyPackages.${system};
        inherit
          self
          inputs
          outputs
          stateVersion
          hostname
          desktop
          flakePath
          ;
        username = user;
      };
      modules = [
        inputs.catppuccin.homeModules.catppuccin
        inputs.zen-browser.homeModules.twilight # beta
        ../home
      ];
    };

  # Helper function for generating host configs
  mkHost =
    {
      hostname,
      desktop ? null,
      pkgsInput ? inputs.unstable,
      system ? "x86_64-linux",
    }:
    pkgsInput.lib.nixosSystem {
      specialArgs = {
        stable = inputs.nixpkgs.legacyPackages.${system};
        inherit
          self
          inputs
          outputs
          stateVersion
          username
          hostname
          desktop
          flakePath
          system
          ;
      };
      modules = [
        inputs.agenix.nixosModules.default
        inputs.lanzaboote.nixosModules.lanzaboote
        ./config.nix
        ../hosts
      ];
    };

    mkDarwin = 
      {
        hostname,
        user ? username,
        system ? "aarch64-darwin",
        desktop ? "null",
      }:
      inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = {
          inherit
            self
            inputs
            outputs
            stateVersion
            username
            hostname
            desktop
            flakePath
            system
            ;
        };
        modules = [
          ./config.nix
          ../hosts
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = ../home;
            };
          }
        ];
      };

  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
