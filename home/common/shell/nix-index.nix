{ inputs, ... }:
{
  # Prebuilt weekly nix-index database (no local `nix-index` run needed):
  # - zsh command-not-found suggests the package providing a missing command
  # - `, <cmd>` (comma) runs a command from nixpkgs without installing it
  imports = [ inputs.nix-index-database.homeModules.default ];

  programs = {
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
  };
}
