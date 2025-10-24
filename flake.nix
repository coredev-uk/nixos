{
  description = "coredev-uk flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "unstable";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "unstable";

    ags.url = "github:/aylur/ags";
    ags.inputs.nixpkgs.follows = "unstable";

    catppuccin.url = "github:catppuccin/nix";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "unstable";

    darwin.url = "github:nix-darwin/nix-darwin";

    lanzaboote.url = "github:nix-community/lanzaboote";
    lanzaboote.inputs.nixpkgs.follows = "unstable";

    nvf.url = "github:notashelf/nvf";

    # TODO: Remove when https://github.com/NixOS/nixpkgs/pull/363992 is merged
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "unstable";
  };

  outputs =
    {
      self,
      unstable,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      stateVersion = "25.05";
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
          pkgs =
            # if builtins.isString (builtins.match "-darwin$" system) then
            if system == "aarch64-darwin" then
              inputs.nixpkgs-darwin.legacyPackages.${system}
            else
              unstable.legacyPackages.${system};
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
          pkgs = unstable.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      formatter = libx.forAllSystems (system: self.packages.${system}.nixfmt-plus);
    };
}
