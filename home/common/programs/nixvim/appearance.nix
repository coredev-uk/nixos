{
  programs.nixvim = {
    # Catppuccin Mocha theme
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        integrations = {
          blink_cmp = true;
          gitsigns = true;
          noice = true;
          snacks = true;
          treesitter = true;
          which_key = true;
          mini.enabled = true;
        };
      };
    };

    plugins = {
      # UI enhancements
      noice = {
        enable = true;
      };

      # Web devicons
      web-devicons.enable = true;

      # Syntax-highlighted completion menu
      colorful-menu = {
        enable = true;
        settings = {
          ls = {
            lua_ls.arguments_hl = "@comment";
            ts_ls.extra_info_hl = "@comment";
          };
          fallback_highlight = "@variable";
          max_width = 60;
        };
      };

      # Mini modules
      mini = {
        enable = true;
        modules = {
          basics = { };
          statusline = { };
          icons = { };
        };
      };
    };
  };
}
