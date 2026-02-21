{
  programs.nixvim.plugins = {
    # Auto-completion
    blink-cmp = {
      enable = true;
      settings = {
        keymap.preset = "default";
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
            draw.treesitter = [ "lsp" ];
          };
        };
        signature = {
          enabled = true;
          window.border = "rounded";
        };
      };
    };

    # Copilot via blink-copilot (auto-enables copilot-lua)
    blink-copilot.enable = true;

    # Copilot settings
    copilot-lua.settings = {
      suggestion.enabled = false;
      panel.enabled = false;
    };

    # Auto-pairs
    nvim-autopairs.enable = true;

    # Comments
    comment.enable = true;
    todo-comments.enable = true;
  };
}
