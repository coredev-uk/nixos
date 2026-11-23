{ inputs, ... }:
{
  # Prebuilt database: command-not-found and `, <cmd>` (comma).
  imports = [ inputs.nix-index-database.homeModules.default ];

  programs = {
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
  };
}
