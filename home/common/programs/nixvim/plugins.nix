{
  programs.nixvim = {
    plugins = {
      sleuth.enable = true;

      snacks = {
        enable = true;
        settings = {
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

          picker.enabled = true;

          explorer.enabled = true;

          input.enabled = true;

          quickfile.enabled = true;

          scope.enabled = true;

          words.enabled = true;

          rename.enabled = true;

          terminal.enabled = true;

          scratch.enabled = true;

          toggle.enabled = true;

          zen.enabled = true;

          dim.enabled = true;
        };
      };
    };
  };
}
