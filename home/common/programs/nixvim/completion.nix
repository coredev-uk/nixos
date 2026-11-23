{
  programs.nixvim.plugins = {
    blink-cmp = {
      enable = true;
      settings = {
        keymap.preset = "super-tab";
        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
            "copilot"
          ];
          providers.copilot = {
            name = "copilot";
            module = "blink-copilot";
            score_offset = 100;
            async = true;
            opts = {
              max_completions = 3;
              max_attempts = 4;
              kind = "Copilot";
              debounce = 750;
              auto_refresh = {
                backward = true;
                forward = true;
              };
            };
          };
        };
        completion = {
          accept.auto_brackets.enabled = true;
          documentation = {
            auto_show = true;
            window.border = "rounded";
          };
          ghost_text.enabled = true;
          menu = {
            border = "rounded";
            draw.components.label = {
              text.__raw = "function(ctx) return require('colorful-menu').blink_components_text(ctx) end";
              highlight.__raw = "function(ctx) return require('colorful-menu').blink_components_highlight(ctx) end";
            };
          };
        };
        signature = {
          enabled = true;
          window.border = "rounded";
        };
      };
    };

    # Auto-enables copilot-lua
    blink-copilot.enable = true;

    copilot-lua.settings = {
      suggestion.enabled = false;
      panel.enabled = false;
    };

    nvim-autopairs.enable = true;

    todo-comments.enable = true;
  };
}
