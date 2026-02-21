{
  programs.nixvim = {
    plugins.which-key.enable = true;

    keymaps = [
      # Git
      {
        key = "<leader>gg";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.lazygit() end";
        options.desc = "Show LazyGit window";
      }
      # File navigation
      {
        key = "<leader>fr";
        mode = "n";
        options.silent = true;
        action = "<cmd>Telescope oldfiles<CR>";
        options.desc = "Show Telescope old files";
      }
      # File explorer
      {
        key = "<leader>m";
        mode = "n";
        options.silent = true;
        action = "<cmd>Neotree toggle<CR>";
        options.desc = "Toggle filetree";
      }
      {
        key = "<leader>n";
        mode = "n";
        options.silent = true;
        action = "<cmd>Neotree reveal<CR>";
        options.desc = "Reveal filetree";
      }
      # LSP actions
      {
        key = "caa";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.code_action() end";
        options.desc = "LSP Code action";
      }
      {
        key = "cgg";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.definition() end";
        options.desc = "LSP Goto definition";
      }
      {
        key = "crr";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.rename() end";
        options.desc = "LSP Rename";
      }
      {
        key = "K";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.hover() end";
        options.desc = "LSP Hover";
      }
    ];
  };
}
