{
  imports = [
    ./options.nix
    ./appearance.nix
    ./lsp.nix
    ./formatting.nix
    ./completion.nix
    ./navigation.nix
    ./git.nix
    ./keymaps.nix
    ./plugins.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
