{ config, pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      treesitter = {
        enable = true;
        highlight.enable = true;
        indent.enable = true;
        # Only languages with servers/formatters/filetypes here; default builds every grammar.
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

      lsp = {
        enable = true;

        servers = {
          astro.enable = true;
          cssls.enable = true;
          html.enable = true;
          tailwindcss.enable = true;

          vtsls.enable = true;

          # nixvim wires vtsls to @vue/typescript-plugin itself; vue_ls only handles template/style (hybrid mode).
          vue_ls.enable = true;

          bashls.enable = true;

          just.enable = true;

          nil_ls.enable = true;

          pyright.enable = true;

          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };

          helm_ls.enable = true;

          oxfmt.enable = true;

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

          marksman.enable = true;
        };
      };

      render-markdown = {
        enable = true;
        settings = {
          file_types = [ "markdown" ];
        };
      };

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

      nvim-ufo = {
        enable = true;
      };
    };

    lsp.inlayHints.enable = true;

    diagnostic.settings = {
      virtual_text = false;
      virtual_lines = {
        current_line = true;
      };
      float.border = "rounded";
    };

    extraPackages = with pkgs; [
      fd # Required by snacks.picker / snacks.explorer
      ripgrep # Required by snacks.picker grep (not in PATH on darwin)
      prettierd # conform formatter (formatting.nix)
      eslint_d # conform formatter + nvim-lint linter
    ];
  };
}
