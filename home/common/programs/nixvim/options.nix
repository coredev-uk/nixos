{
  programs.nixvim = {
    opts = {
      tabstop = 2;
      shiftwidth = 2;
      softtabstop = 2;
      expandtab = true;

      clipboard = "unnamedplus";

      number = true;
      relativenumber = true;

      smartindent = true;

      foldcolumn = "1";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;

      laststatus = 3;

      ignorecase = true;
      smartcase = true;

      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;
      scrolloff = 8;

      splitright = true;
      splitbelow = true;

      undofile = true;
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    luaLoader.enable = true;
  };
}
