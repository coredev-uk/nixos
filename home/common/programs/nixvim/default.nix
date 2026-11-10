{
  imports = [
    ./options.nix
    ./appearance.nix
    ./lsp.nix
    ./formatting.nix
    ./completion.nix
    ./git.nix
    ./keymaps.nix
    ./plugins.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    nixpkgs.useGlobalPackages = true;
    viAlias = true;
    vimAlias = true;

    performance = {
      byteCompileLua = {
        enable = true;
        nvimRuntime = true;
        configs = true;
        plugins = true;
      };
      combinePlugins = {
        enable = true;
        # Ships its own queries/lua/highlights.scm, which collides with the treesitter queries.
        standalonePlugins = [
          "snacks.nvim"
          "conform.nvim"
        ];
      };
    };
  };
}
