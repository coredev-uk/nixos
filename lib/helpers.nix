{
  self,
  inputs,
  outputs,
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

  # home.stateVersion is pinned per home configuration (in flake.nix) and must
  # never be bumped on upgrades; see the Home Manager manual.
  mkHomeManager =
    { flakeInputs, stateVersion }:
    {
      imports = [
        flakeInputs.nixvim.homeModules.nixvim
        ../home # This path is relative to where this function is defined and used
      ];
      home.stateVersion = stateVersion;
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
      stateVersion,
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
          inherit stateVersion;
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
        # inputs.agenix.nixosModules.default
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
      flakePath ? "/Users/${user}/.dotfiles",
      homeStateVersion,
    }:
    # No `system`/`pkgs` args: a passed `pkgs` is mkForce'd over the nixpkgs module,
    # discarding nixpkgs.overlays/config. hosts/<host>/hardware.nix sets
    # nixpkgs.hostPlatform, and nix-darwin's nixpkgs input follows `unstable`.
    inputs.nix-darwin.lib.darwinSystem {
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
        inputs.nix-homebrew.darwinModules.nix-homebrew
        ../hosts
        {
          home-manager = {
            #useGlobalPkgs = true;
            useUserPackages = true;
            users."${user}" = mkHomeManager {
              flakeInputs = inputs;
              stateVersion = homeStateVersion;
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
    "x86_64-linux"
    "aarch64-darwin"
  ];
}
