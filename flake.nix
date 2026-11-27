{
  description = "coredev-uk flake";

  inputs = {
    # ADE dashboard (home/common/dev/ade.nix). No nixpkgs follows: its flake pins the Go toolchain
    # its vendorHash uses.
    ade.url = "github:coredev-uk/ade";

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
    # No nixpkgs follows: wine-astral, dxvk and mingw are only in nix-citizen.cachix.org when
    # built against its own nixpkgs pin.
    nix-citizen.inputs.treefmt-nix.follows = "treefmt-nix";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "unstable";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "unstable";

    # hermes (hosts/hermes): Raspberry Pi kernel, firmware and boot loader. No nixpkgs follows: its
    # kernel is only in nixos-raspberrypi.cachix.org when built against its own nixpkgs pin.
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    # athena's NixOS-WSL side (hosts/athena).
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    nixcord.url = "github:FlameFlag/nixcord";
    nixcord.inputs.nixpkgs.follows = "unstable";
    # Only nixcord's own tests/CI shell. `nixpkgs-packages` stays pinned: it asserts an exact Node.js.
    nixcord.inputs.home-manager.follows = "home-manager";
    nixcord.inputs.nix-darwin.follows = "nix-darwin";
    nixcord.inputs.treefmt-nix.follows = "treefmt-nix";
    nixcord.inputs.nixpkgs-ci.follows = "unstable";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "unstable";

    # Built from source, no upstream cache; CI builds it into Attic. darwin-x64 pair is for Intel
    # Macs only (unused).
    omp.url = "github:can1357/oh-my-pi";
    omp.inputs.nixpkgs.follows = "unstable";
    omp.inputs.nixpkgs-darwin-x64.follows = "unstable";
    omp.inputs.bun2nix-darwin-x64.follows = "omp/bun2nix";

    # Sona (home/common/programs/sona.nix); `nix` branch carries CI-pinned builds. No nixpkgs
    # follows: its flake pins the nixpkgs it's developed against.
    sona.url = "github:coredev-uk/sona-go/nix";

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

      # Match the editor's formatter versions (home-manager uses unstable).
      treefmtFor =
        system:
        inputs.treefmt-nix.lib.evalModule inputs.unstable.legacyPackages.${system}
          ./home/common/dev/treefmt.nix;
    in
    {
      # stateVersion = HM release of first activation; never bump.
      homeConfigurations = {
        "${username}@atlas" = libx.mkHome {
          hostname = "atlas";
          desktop = "hyprland";
          stateVersion = "26.05";
        };
        # NixOS-WSL on athena (atlas's Windows install).
        "${username}@athena" = libx.mkHome {
          hostname = "athena";
          type = "wsl";
          stateVersion = "26.05";
        };
      };

      nixosConfigurations = {
        atlas = libx.mkHost {
          hostname = "atlas";
          desktop = "hyprland";
        };
        athena = libx.mkHost {
          hostname = "athena";
          type = "wsl";
        };
        # Raspberry Pi 4 on the IoT VLAN: Home Assistant's Bluetooth proxy (home-ops).
        hermes = libx.mkHost {
          hostname = "hermes";
          system = "aarch64-linux";
        };
      };

      darwinConfigurations = {
        poseidon = libx.mkDarwin {
          hostname = "poseidon";
          homeStateVersion = "26.05";
        };
      };

      # Custom packages ('nix build .#<pkg>')
      packages = libx.forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./pkgs { inherit pkgs; }
      );

      # Overlays
      overlays = import ./overlays { inherit inputs; };

      # Bootstrap shell ('nix develop')
      devShells = libx.forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      formatter = libx.forAllSystems (system: (treefmtFor system).config.build.wrapper);

      # `nix flake check` fails on unformatted files, or on an overlay without a removal condition
      # (overlays/expiry.nix) and vice versa. Eval-only: attribute names, no package is built.
      checks = libx.forAllSystems (
        system:
        let
          inherit (import ./overlays/expiry.nix { inherit inputs; }) coverage;
          problems =
            map (n: "overlay `${n}` has no entry in overlays/expiry.nix") coverage.withoutCondition
            ++ map (n: "overlays/expiry.nix entry `${n}` has no overlay") coverage.withoutOverlay;
        in
        {
          formatting = (treefmtFor system).config.build.check self;

          overlay-expiry = inputs.unstable.legacyPackages.${system}.runCommand "overlay-expiry" { } (
            if problems == [ ] then
              "touch $out"
            else
              ''
                cat >&2 <<'EOF'
                ${builtins.concatStringsSep "\n" problems}
                EOF
                exit 1
              ''
          );
        }
      );
    };
}
