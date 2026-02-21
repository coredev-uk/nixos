{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      # Auto-detect indentation
      sleuth.enable = true;

      # Snacks utilities
      snacks = {
        enable = true;
        settings = {
          #--------------------------------------------------------------------
          # Already enabled features
          #--------------------------------------------------------------------
          lazygit.enabled = true;
          bigfile.enabled = true;
          notifier.enabled = true;
          git.enabled = true;
          gitbrowse.enabled = true;
          scroll.enabled = true;
          indent = {
            enabled = true;
            indent.only_scope = true;
          };
          statuscolumn.enabled = true;

          #--------------------------------------------------------------------
          # Dashboard
          #--------------------------------------------------------------------
          dashboard = {
            enabled = true;
            width = 60;
            preset = {
              keys = [
                {
                  icon = " ";
                  key = "f";
                  desc = "Find File";
                  action.__raw = "function() Snacks.picker.files() end";
                }
                {
                  icon = " ";
                  key = "n";
                  desc = "New File";
                  action = ":ene | startinsert";
                }
                {
                  icon = " ";
                  key = "g";
                  desc = "Find Text";
                  action.__raw = "function() Snacks.picker.grep() end";
                }
                {
                  icon = " ";
                  key = "r";
                  desc = "Recent Files";
                  action.__raw = "function() Snacks.picker.recent() end";
                }
                {
                  icon = " ";
                  key = "c";
                  desc = "Config";
                  action.__raw = "function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end";
                }
                {
                  icon = "󰒲 ";
                  key = "u";
                  desc = "Check Updates";
                  action = ":Lazy check";
                }
                {
                  icon = " ";
                  key = "q";
                  desc = "Quit";
                  action = ":qa";
                }
              ];
            };
            sections = [
              {
                section = "header";
              }
              {
                icon = " ";
                title = "Keymaps";
                section = "keys";
                indent = 2;
                padding = 1;
              }
              {
                icon = " ";
                title = "Recent Files";
                section = "recent_files";
                indent = 2;
                padding = 1;
              }
              {
                icon = " ";
                title = "Projects";
                section = "projects";
                indent = 2;
                padding = 1;
              }
            ];
          };

          #--------------------------------------------------------------------
          # Picker (replaces telescope)
          #--------------------------------------------------------------------
          picker.enabled = true;

          #--------------------------------------------------------------------
          # Explorer (replaces neo-tree)
          #--------------------------------------------------------------------
          explorer.enabled = true;

          #--------------------------------------------------------------------
          # Input (better vim.ui.input)
          #--------------------------------------------------------------------
          input.enabled = true;

          #--------------------------------------------------------------------
          # Quick file (instant render before plugins load)
          #--------------------------------------------------------------------
          quickfile.enabled = true;

          #--------------------------------------------------------------------
          # Scope detection + text objects
          #--------------------------------------------------------------------
          scope.enabled = true;

          #--------------------------------------------------------------------
          # Word references (highlight + jump)
          #--------------------------------------------------------------------
          words.enabled = true;

          #--------------------------------------------------------------------
          # Rename (LSP-aware file rename)
          #--------------------------------------------------------------------
          rename.enabled = true;

          #--------------------------------------------------------------------
          # Terminal
          #--------------------------------------------------------------------
          terminal.enabled = true;

          #--------------------------------------------------------------------
          # Scratch buffers
          #--------------------------------------------------------------------
          scratch.enabled = true;

          #--------------------------------------------------------------------
          # Toggle helpers
          #--------------------------------------------------------------------
          toggle.enabled = true;

          #--------------------------------------------------------------------
          # Zen mode
          #--------------------------------------------------------------------
          zen.enabled = true;

          #--------------------------------------------------------------------
          # Dim (out-of-scope dimming)
          #--------------------------------------------------------------------
          dim.enabled = true;
        };
      };
    };

    # Extra plugins not managed by nixvim modules
    extraPlugins = with pkgs.vimPlugins; [
      yuck-vim
    ];
  };
}
