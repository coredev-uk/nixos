{
  self,
  inputs,
  outputs,
  stateVersion,
  username,
  ...
}:
let
  # Helper function to generate common specialArgs
  mkSpecialArgs =
    {
      hostname,
      user ? username,
      desktop ? null,
      type ? "desktop",
      system ? "x86_64-linux",
      flakePath ? "/home/${user}/.dotfiles",
    }:
    {
      inherit
        self
        inputs
        outputs
        ;
      unstable = inputs.unstable.legacyPackages.${system};
      meta = {
        inherit
          hostname
          desktop
          stateVersion
          flakePath
          system
          ;
        homeDirectory = if type == "darwin" then "/Users/${user}" else "/home/${user}";
        username = user;
        isDesktop = builtins.isString desktop;
        isDarwin = type == "darwin";
        isHeadless = type == "server" || (type != "darwin" && type != "desktop");
      };
    };

  mkHomeManager =
    { flakeInputs, flakeStateVersion }:
    {
      imports = [
        flakeInputs.agenix.homeManagerModules.default
        flakeInputs.catppuccin.homeModules.catppuccin
        ../home # This path is relative to where this function is defined and used
      ];
      home.stateVersion = flakeStateVersion;
    };
in
{
  # Helper function for generating home-manager configs (nixos / linux configs)
  mkHome =
    {
      hostname,
      user ? username,
      desktop ? null,
      type ? "desktop",
      pkgs ? inputs.unstable,
      system ? "x86_64-linux",
      flakePath ? "/home/${user}/.dotfiles",
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgs.legacyPackages.${system};
      extraSpecialArgs = mkSpecialArgs {
        inherit
          hostname
          user
          desktop
          type
          system
          flakePath
          ;
      };
      modules = [
        (mkHomeManager {
          flakeInputs = inputs;
          flakeStateVersion = stateVersion;
        })
      ];
    };

  # Helper function for generating host configs
  mkHost =
    {
      hostname,
      user ? username,
      desktop ? null,
      type ? "desktop",
      pkgs ? inputs.nixpkgs,
      system ? "x86_64-linux",
      flakePath ? "/home/${user}/.dotfiles",
    }:
    pkgs.lib.nixosSystem {
      specialArgs = mkSpecialArgs {
        inherit
          hostname
          user
          desktop
          type
          system
          flakePath
          ;
      };
      modules = [
        inputs.agenix.nixosModules.default
        inputs.lanzaboote.nixosModules.lanzaboote
        ../hosts
      ];
    };

  mkDarwin =
    {
      hostname,
      user ? username,
      system ? "aarch64-darwin",
      desktop ? null,
      type ? "darwin",
      pkgs ? inputs.unstable,
      flakePath ? "/Users/${user}/.dotfiles",
    }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      pkgs = import pkgs {
        inherit system;
        config.allowUnfree = true;
      };
      specialArgs = mkSpecialArgs {
        inherit
          hostname
          user
          system
          desktop
          type
          flakePath
          ;
      };
      modules = [
        inputs.home-manager.darwinModules.home-manager
        ../hosts
        {
          home-manager = {
            #useGlobalPkgs = true;
            useUserPackages = true;
            users."${user}" = mkHomeManager {
              flakeInputs = inputs;
              flakeStateVersion = stateVersion;
            };
            backupFileExtension = "backup";
            extraSpecialArgs = mkSpecialArgs {
              inherit
                hostname
                user
                system
                desktop
                type
                flakePath
                ;
            };
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
