{
  description = "coredev-uk flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    home-manager-darwin.url = "github:nix-community/home-manager/release-25.11";

    # accessible from pkgs.unstable overlay
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "unstable";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "unstable";

    catppuccin.url = "github:catppuccin/nix/release-25.11";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "unstable";

    # TODO: Pinned until is more stable after handover
    nixcord.url = "github:FlameFlag/nixcord/02c730b57b8ef16c62624a3410ef724d014c58db";

    nvf.url = "github:notashelf/nvf";

    opencode.url = "github:anomalyco/opencode";

    # TODO: Remove when https://github.com/NixOS/nixpkgs/pull/363992 is merged
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      unstable,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      stateVersion = "25.11";
      username = "paul";

      libx = import ./lib {
        inherit
          self
          inputs
          outputs
          username
          stateVersion
          ;
      };
    in
    {
      # Home Manager configurations
      homeConfigurations = {
        "${username}@atlas" = libx.mkHome {
          hostname = "atlas";
          desktop = "hyprland"; # hyprland or i3
        };
        "${username}@hyperion" = libx.mkHome {
          hostname = "hyperion";
          type = "server";
          user = "${username}";
        };
      };

      # NixOS configurations
      nixosConfigurations = {
        atlas = libx.mkHost {
          hostname = "atlas";
          desktop = "hyprland"; # hyprland or i3
        };
        hyperion = libx.mkHost {
          hostname = "hyperion";
          type = "server";
        };
      };

      # Nix Darwin configurations
      darwinConfigurations = {
        poseidon = libx.mkDarwin {
          hostname = "poseidon";
        };
      };

      # Custom packages; acessible via 'nix build', 'nix shell', etc
      packages = libx.forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./pkgs { inherit pkgs inputs; }
      );

      # Custom overlays
      overlays = import ./overlays { inherit inputs; };

      # Devshell for bootstrapping
      # Accessible via 'nix develop' or 'nix-shell' (legacy)
      devShells = libx.forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      formatter = libx.forAllSystems (system: self.packages.${system}.nixfmt-plus);
    };
}
