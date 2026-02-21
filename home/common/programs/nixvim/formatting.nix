{
  programs.nixvim.plugins.conform-nvim = {
    enable = true;
    settings = {
      formatters_by_ft = {
        astro = [
          "prettierd"
          "eslint_d"
        ];
        typescript = [ "prettierd" ];
        javascript = [ "prettierd" ];
        typescriptreact = [ "prettierd" ];
        javascriptreact = [ "prettierd" ];
        vue = [
          "prettierd"
          "eslint_d"
        ];
        nix = [ "nixfmt" ];
        yaml = [ "yamlfmt" ];
        css = [ "prettierd" ];
        html = [ "prettierd" ];
        json = [ "prettierd" ];
        markdown = [ "prettierd" ];
      };
      format_on_save = {
        timeout_ms = 3000;
        lsp_format = "fallback";
      };
    };
  };
}
