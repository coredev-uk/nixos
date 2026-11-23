{
  self,
  inputs,
  outputs,
  username,
  ...
}:
let
  monitors = import ./monitors.nix;

  # Extra arguments (stateVersion, pkgs, …) are the callers'.
  mkSpecialArgs =
    {
      hostname,
      user ? username,
      desktop ? null,
      type ? "desktop",
      system ? "x86_64-linux",
      ...
    }:
    let
      homeDirectory = if type == "darwin" then "/Users/${user}" else "/home/${user}";
    in
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
          system
          homeDirectory
          ;
        username = user;
        flakePath = "${homeDirectory}/.dotfiles";
        # Hyprland's layout; the first is the primary (gaming) screen.
        monitors = monitors.${hostname} or monitors.default;
        isDesktop = builtins.isString desktop;
        isDarwin = type == "darwin";
        # Home Manager on a WSL distro (not NixOS): workstation without a desktop.
        isWSL = type == "wsl";
      };
    };

  # home.stateVersion is pinned per config in flake.nix; never bump.
  mkHomeManager = stateVersion: {
    imports = [
      inputs.nixvim.homeModules.nixvim
      ../home
    ];
    home.stateVersion = stateVersion;
  };
in
{
  mkHome =
    {
      stateVersion,
      pkgs ? inputs.unstable,
      ...
    }@args:
    let
      specialArgs = mkSpecialArgs args;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgs.legacyPackages.${specialArgs.meta.system};
      extraSpecialArgs = specialArgs;
      modules = [ (mkHomeManager stateVersion) ];
    };

  mkHost =
    {
      pkgs ? inputs.nixpkgs,
      ...
    }@args:
    pkgs.lib.nixosSystem {
      specialArgs = mkSpecialArgs args;
      modules = [ ../hosts ];
    };

  # No `system`/`pkgs` args: a passed `pkgs` is mkForce'd over the nixpkgs module, discarding
  # overlays/config. hosts/<host>/hardware.nix sets hostPlatform; nix-darwin's nixpkgs follows `unstable`.
  mkDarwin =
    { homeStateVersion, ... }@args:
    let
      specialArgs = mkSpecialArgs (
        {
          type = "darwin";
          system = "aarch64-darwin";
        }
        // args
      );
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit specialArgs;
      modules = [
        inputs.home-manager.darwinModules.home-manager
        inputs.nix-homebrew.darwinModules.nix-homebrew
        ../hosts
        {
          home-manager = {
            # Same pkgs as the system (hosts/default.nix: same overlays/config), no second nixpkgs.
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${specialArgs.meta.username} = mkHomeManager homeStateVersion;
            backupFileExtension = "backup";
            extraSpecialArgs = specialArgs;
          };
        }
      ];
    };

  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "x86_64-linux"
    "aarch64-darwin"
  ];
}
