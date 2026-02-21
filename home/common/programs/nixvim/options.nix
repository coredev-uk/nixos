{
  programs.nixvim = {
    opts = {
      # Tab / indentation
      tabstop = 2;
      shiftwidth = 2;
      softtabstop = 2;
      expandtab = true;

      # System clipboard
      clipboard = "unnamedplus";

      # Line numbers
      number = true;
      relativenumber = true;

      # Better indentation
      smartindent = true;

      # Folding
      foldcolumn = "1";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;

      # Global statusline
      laststatus = 3;

      # Search
      ignorecase = true;
      smartcase = true;

      # UI
      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;
      scrolloff = 8;

      # Splits
      splitright = true;
      splitbelow = true;

      # Undo
      undofile = true;
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    luaLoader.enable = true;
  };
}
