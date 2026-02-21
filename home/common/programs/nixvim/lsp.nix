{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      # Treesitter
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
        };
      };

      # LSP
      lsp = {
        enable = true;
        inlayHints = true;

        servers = {
          # Web
          astro.enable = true;
          cssls.enable = true;
          html.enable = true;
          tailwindcss.enable = true;

          # TypeScript / JavaScript
          vtsls = {
            enable = true;
            filetypes = [
              "typescript"
              "javascript"
              "typescriptreact"
              "javascriptreact"
            ];
          };

          # Vue (hybrid mode - volar handles .vue, vtsls handles .ts/.js)
          volar = {
            enable = true;
            filetypes = [
              "vue"
              "typescript"
              "javascript"
            ];
            extraOptions.init_options.vue.hybridMode = true;
          };

          # Shell
          bashls.enable = true;

          # Nix
          nil_ls.enable = true;

          # PHP
          phpactor.enable = true;

          # Python
          pyright.enable = true;

          # Rust
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };

          # Helm
          helm_ls.enable = true;

          # YAML
          yamlls.enable = true;

          # Markdown
          marksman.enable = true;
        };
      };

      # Render markdown nicely
      render-markdown = {
        enable = true;
        settings = {
          file_types = [
            "markdown"
            "Avante"
          ];
        };
      };

      # Linting
      lint = {
        enable = true;
        lintersByFt = {
          javascript = [ "eslint_d" ];
          typescript = [ "eslint_d" ];
          javascriptreact = [ "eslint_d" ];
          typescriptreact = [ "eslint_d" ];
          vue = [ "eslint_d" ];
          astro = [ "eslint_d" ];
          nix = [ "statix" ];
        };
      };

      # Code folding with nvim-ufo
      nvim-ufo = {
        enable = true;
      };
    };

    # Diagnostics
    diagnostic.settings = {
      virtual_text = false;
      virtual_lines = {
        current_line = true;
      };
      float.border = "rounded";
    };

    # LSP handler borders
    extraConfigLua = ''
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
    '';

    # Extra packages for LSP servers and tools
    extraPackages = with pkgs; [
      fd # Required by snacks.picker / snacks.explorer
      yamlfmt
    ];
  };
}
