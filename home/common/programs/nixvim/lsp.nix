{ config, pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      # Treesitter
      treesitter = {
        enable = true;
        highlight.enable = true;
        indent.enable = true;
        # Only the languages this config has servers, formatters or filetypes for; the
        # default builds every grammar.
        grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
          astro
          bash
          css
          diff
          gitcommit
          gotmpl
          helm
          html
          javascript
          json
          just
          lua
          markdown
          markdown_inline
          nix
          python
          query
          regex
          rust
          toml
          tsx
          typescript
          vim
          vimdoc
          vue
          yaml
        ];
      };

      # LSP
      lsp = {
        enable = true;

        servers = {
          # Web
          astro.enable = true;
          cssls.enable = true;
          html.enable = true;
          tailwindcss.enable = true;

          # TypeScript / JavaScript
          vtsls.enable = true;

          # Vue: nixvim wires vtsls to the @vue/typescript-plugin itself, so vue_ls only
          # handles the .vue template/style side (hybrid mode is the server's only mode).
          vue_ls.enable = true;

          # Shell
          bashls.enable = true;

          # Just Files
          just.enable = true;

          # Nix
          nil_ls.enable = true;

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

          # Mixed
          oxfmt.enable = true;

          # YAML
          yamlls = {
            enable = true;
            settings = {
              yaml = {
                schemas = {
                  "https://kubernetes-schemas-ecq.pages.dev/cert-manager.io/certificate_v1.json" = [
                    "**/certificates/*.yaml"
                  ];
                };
              };
            };
          };

          # Markdown
          marksman.enable = true;
        };
      };

      # Render markdown nicely
      render-markdown = {
        enable = true;
        settings = {
          file_types = [ "markdown" ];
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
    lsp.inlayHints.enable = true;

    diagnostic.settings = {
      virtual_text = false;
      virtual_lines = {
        current_line = true;
      };
      float.border = "rounded";
    };

    # Extra packages for LSP servers and tools
    extraPackages = with pkgs; [
      fd # Required by snacks.picker / snacks.explorer
      ripgrep # Required by snacks.picker grep (not in PATH on darwin)
      prettierd # conform formatter (formatting.nix)
      eslint_d # conform formatter + nvim-lint linter
    ];
  };
}
