{
  self,
  inputs,
  outputs,
  username,
  ...
}:
let
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
      # Imported (not legacyPackages) so config/unfree and the flake's overlays apply.
      unstable = import inputs.unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          outputs.overlays.additions
          outputs.overlays.modifications
        ];
      };
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
        # Home Manager on a WSL distro (not NixOS): workstation without a desktop.
        isWSL = type == "wsl";
        isHeadless =
          !builtins.elem type [
            "darwin"
            "desktop"
            "wsl"
          ];
      };
    };

  # home.stateVersion is pinned per config in flake.nix; never bump.
  mkHomeManager =
    { flakeInputs, stateVersion }:
    {
      imports = [
        flakeInputs.nixvim.homeModules.nixvim
        ../home
      ];
      home.stateVersion = stateVersion;
    };
in
{
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
    # No `system`/`pkgs` args: a passed `pkgs` is mkForce'd over the nixpkgs module, discarding
    # overlays/config. hosts/<host>/hardware.nix sets hostPlatform; nix-darwin's nixpkgs follows `unstable`.
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
            # Same pkgs as the system (hosts/default.nix: same overlays/config), no second nixpkgs.
            useGlobalPkgs = true;
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
