{
  description = "coredev-uk flake";

  inputs = {
    catppuccin.url = "github:catppuccin/nix";
    catppuccin.inputs.nixpkgs.follows = "unstable";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "unstable";

    impeccable.url = "github:pbakaus/impeccable";
    impeccable.flake = false;

    lanzaboote.url = "github:nix-community/lanzaboote/v1.2.0";
    lanzaboote.inputs.nixpkgs.follows = "unstable";

    macos-wallpapers.url = "github:coredev-uk/macos-wallpapers";
    macos-wallpapers.inputs.nixpkgs.follows = "unstable";

    nix-citizen.url = "github:LovingMelody/nix-citizen";
    # No nixpkgs follows on purpose: wine-astral, dxvk and the mingw cross toolchain are
    # only in nix-citizen.cachix.org when built against nix-citizen's own nixpkgs pin.
    # Following ours rebuilt them from source on every CI run and switch.
    nix-citizen.inputs.treefmt-nix.follows = "treefmt-nix";

    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "unstable";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "unstable";

    nixcord.url = "github:FlameFlag/nixcord";
    nixcord.inputs.nixpkgs.follows = "unstable";
    # Only used by nixcord's own tests/formatter/CI shell. `nixpkgs-packages` is
    # left pinned on purpose: its packages assert an exact Node.js version.
    nixcord.inputs.home-manager.follows = "home-manager";
    nixcord.inputs.nix-darwin.follows = "nix-darwin";
    nixcord.inputs.treefmt-nix.follows = "treefmt-nix";
    nixcord.inputs.nixpkgs-ci.follows = "unstable";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "unstable";

    taste-skill.url = "github:Leonxlnx/taste-skill";
    taste-skill.flake = false;

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "unstable";

    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # TODO: Remove when https://github.com/NixOS/nixpkgs/pull/363992 is merged
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs = {
        nixpkgs.follows = "unstable";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      username = "paul";

      libx = import ./lib {
        inherit
          self
          inputs
          outputs
          username
          ;
      };
    in
    {
      # Home Manager configurations
      # stateVersion = HM release of the first activation; never bump it on upgrades.
      homeConfigurations = {
        "${username}@atlas" = libx.mkHome {
          hostname = "atlas";
          desktop = "hyprland";
          stateVersion = "26.05";
        };
      };

      # NixOS configurations
      nixosConfigurations = {
        atlas = libx.mkHost {
          hostname = "atlas";
          desktop = "hyprland";
        };
      };

      # Nix Darwin configurations
      darwinConfigurations = {
        poseidon = libx.mkDarwin {
          hostname = "poseidon";
          homeStateVersion = "26.05";
        };
      };

      # Custom packages; acessible via 'nix build', 'nix shell', etc
      packages = libx.forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./pkgs { inherit pkgs; }
      );

      # Custom overlays
      overlays = import ./overlays { inherit inputs; };

      # Devshell for bootstrapping
      # Accessible via 'nix develop'
      devShells = libx.forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      formatter = libx.forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./home/common/dev/treefmt.nix;
        in
        treefmtEval.config.build.wrapper
      );
    };
}
