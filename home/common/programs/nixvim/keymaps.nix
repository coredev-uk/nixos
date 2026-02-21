{
  programs.nixvim = {
    plugins.which-key = {
      enable = true;
      settings.spec = [
        {
          __unkeyed-1 = "<leader>f";
          group = "Find";
        }
        {
          __unkeyed-1 = "<leader>g";
          group = "Git";
        }
        {
          __unkeyed-1 = "<leader>l";
          group = "LSP";
        }
        {
          __unkeyed-1 = "<leader>u";
          group = "Toggle";
        }
        {
          __unkeyed-1 = "<leader>b";
          group = "Buffer";
        }
        {
          __unkeyed-1 = "<leader>h";
          group = "Hunks";
        }
        {
          __unkeyed-1 = "<leader>x";
          group = "Diagnostics";
        }
      ];
    };

    keymaps = [
      #------------------------------------------------------------------------
      # FIND / PICKER
      #------------------------------------------------------------------------
      {
        key = "<leader>ff";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.files() end";
        options.desc = "Find files";
      }
      {
        key = "<leader>fg";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.grep() end";
        options.desc = "Live grep";
      }
      {
        key = "<leader>fb";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.buffers() end";
        options.desc = "Buffers";
      }
      {
        key = "<leader>fh";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.help() end";
        options.desc = "Help tags";
      }
      {
        key = "<leader>fr";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.recent() end";
        options.desc = "Recent files";
      }
      {
        key = "<leader>f/";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.grep_buffers() end";
        options.desc = "Grep open buffers";
      }
      {
        key = "<leader>fc";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end";
        options.desc = "Find config files";
      }
      {
        key = "<leader>fw";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.grep_word() end";
        options.desc = "Grep word under cursor";
      }
      {
        key = "<leader>fm";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.marks() end";
        options.desc = "Marks";
      }
      {
        key = "<leader>fk";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.keymaps() end";
        options.desc = "Keymaps";
      }
      {
        key = "<leader>f:";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.command_history() end";
        options.desc = "Command history";
      }
      {
        key = "<leader>fd";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.diagnostics() end";
        options.desc = "Diagnostics";
      }
      {
        key = "<leader>fD";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.diagnostics_buffer() end";
        options.desc = "Buffer diagnostics";
      }
      {
        key = "<leader>fR";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.resume() end";
        options.desc = "Resume last picker";
      }
      {
        key = "<leader>fp";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.projects() end";
        options.desc = "Projects";
      }
      {
        key = "<leader>fs";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.lsp_symbols() end";
        options.desc = "LSP document symbols";
      }
      {
        key = "<leader>fS";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.lsp_workspace_symbols() end";
        options.desc = "LSP workspace symbols";
      }
      {
        key = "<leader>ft";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.treesitter() end";
        options.desc = "Treesitter symbols";
      }
      {
        key = "<leader>fu";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.undo() end";
        options.desc = "Undo history";
      }
      {
        key = "<leader>f\"";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.registers() end";
        options.desc = "Registers";
      }
      {
        key = "<leader>fq";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.qflist() end";
        options.desc = "Quickfix list";
      }

      #------------------------------------------------------------------------
      # FILE EXPLORER
      #------------------------------------------------------------------------
      {
        key = "<leader>e";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.explorer() end";
        options.desc = "File explorer";
      }

      #------------------------------------------------------------------------
      # GIT
      #------------------------------------------------------------------------
      {
        key = "<leader>gg";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.lazygit() end";
        options.desc = "LazyGit";
      }
      {
        key = "<leader>gl";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.git_log() end";
        options.desc = "Git log";
      }
      {
        key = "<leader>gL";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.git_log_file() end";
        options.desc = "Git log (current file)";
      }
      {
        key = "<leader>gb";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.git_branches() end";
        options.desc = "Git branches";
      }
      {
        key = "<leader>gs";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.git_status() end";
        options.desc = "Git status";
      }
      {
        key = "<leader>gS";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.git_stash() end";
        options.desc = "Git stash";
      }
      {
        key = "<leader>gd";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.git_diff() end";
        options.desc = "Git diff";
      }
      {
        key = "<leader>gB";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.gitbrowse() end";
        options.desc = "Git browse (open in browser)";
      }

      # Gitsigns hunk navigation
      {
        key = "]c";
        mode = "n";
        options.silent = true;
        action.__raw = ''
          function()
            if vim.wo.diff then return "]c" end
            vim.schedule(function() require("gitsigns").next_hunk() end)
            return "<Ignore>"
          end
        '';
        options.desc = "Next hunk";
        options.expr = true;
      }
      {
        key = "[c";
        mode = "n";
        options.silent = true;
        action.__raw = ''
          function()
            if vim.wo.diff then return "[c" end
            vim.schedule(function() require("gitsigns").prev_hunk() end)
            return "<Ignore>"
          end
        '';
        options.desc = "Previous hunk";
        options.expr = true;
      }
      {
        key = "<leader>hs";
        mode = "n";
        options.silent = true;
        action.__raw = "function() require('gitsigns').stage_hunk() end";
        options.desc = "Stage hunk";
      }
      {
        key = "<leader>hr";
        mode = "n";
        options.silent = true;
        action.__raw = "function() require('gitsigns').reset_hunk() end";
        options.desc = "Reset hunk";
      }
      {
        key = "<leader>hs";
        mode = "v";
        options.silent = true;
        action.__raw = "function() require('gitsigns').stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end";
        options.desc = "Stage hunk (visual)";
      }
      {
        key = "<leader>hr";
        mode = "v";
        options.silent = true;
        action.__raw = "function() require('gitsigns').reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end";
        options.desc = "Reset hunk (visual)";
      }
      {
        key = "<leader>hu";
        mode = "n";
        options.silent = true;
        action.__raw = "function() require('gitsigns').undo_stage_hunk() end";
        options.desc = "Undo stage hunk";
      }
      {
        key = "<leader>hS";
        mode = "n";
        options.silent = true;
        action.__raw = "function() require('gitsigns').stage_buffer() end";
        options.desc = "Stage buffer";
      }
      {
        key = "<leader>hR";
        mode = "n";
        options.silent = true;
        action.__raw = "function() require('gitsigns').reset_buffer() end";
        options.desc = "Reset buffer";
      }
      {
        key = "<leader>hp";
        mode = "n";
        options.silent = true;
        action.__raw = "function() require('gitsigns').preview_hunk() end";
        options.desc = "Preview hunk";
      }
      {
        key = "<leader>hb";
        mode = "n";
        options.silent = true;
        action.__raw = "function() require('gitsigns').blame_line({ full = true }) end";
        options.desc = "Blame line";
      }
      {
        key = "<leader>hd";
        mode = "n";
        options.silent = true;
        action.__raw = "function() require('gitsigns').diffthis() end";
        options.desc = "Diff this";
      }
      {
        key = "<leader>hD";
        mode = "n";
        options.silent = true;
        action.__raw = "function() require('gitsigns').diffthis('~') end";
        options.desc = "Diff project";
      }

      #------------------------------------------------------------------------
      # LSP
      #------------------------------------------------------------------------
      {
        key = "<leader>la";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.code_action() end";
        options.desc = "Code action";
      }
      {
        key = "<leader>ln";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.rename() end";
        options.desc = "Rename symbol";
      }
      {
        key = "<leader>lf";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.format({ async = true }) end";
        options.desc = "Format";
      }
      {
        key = "<leader>lh";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.hover() end";
        options.desc = "Hover";
      }
      {
        key = "<leader>ls";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.signature_help() end";
        options.desc = "Signature help";
      }
      {
        key = "<leader>le";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.diagnostic.open_float() end";
        options.desc = "Diagnostic float";
      }
      {
        key = "K";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.hover() end";
        options.desc = "LSP Hover";
      }

      # LSP navigation via snacks picker
      {
        key = "gd";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.lsp_definitions() end";
        options.desc = "Go to definition";
      }
      {
        key = "gD";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.lsp.buf.declaration() end";
        options.desc = "Go to declaration";
      }
      {
        key = "gr";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.lsp_references() end";
        options.desc = "References";
      }
      {
        key = "gI";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.lsp_implementations() end";
        options.desc = "Implementations";
      }
      {
        key = "gy";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.picker.lsp_type_definitions() end";
        options.desc = "Type definition";
      }
      {
        key = "]d";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.diagnostic.goto_next() end";
        options.desc = "Next diagnostic";
      }
      {
        key = "[d";
        mode = "n";
        options.silent = true;
        action.__raw = "function() vim.diagnostic.goto_prev() end";
        options.desc = "Previous diagnostic";
      }

      #------------------------------------------------------------------------
      # WORD REFERENCES (snacks.words)
      #------------------------------------------------------------------------
      {
        key = "]]";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.words.jump(vim.v.count1) end";
        options.desc = "Next reference";
      }
      {
        key = "[[";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.words.jump(-vim.v.count1) end";
        options.desc = "Previous reference";
      }

      #------------------------------------------------------------------------
      # BUFFER
      #------------------------------------------------------------------------
      {
        key = "<leader>bd";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.bufdelete() end";
        options.desc = "Delete buffer";
      }
      {
        key = "<leader>bo";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.bufdelete.other() end";
        options.desc = "Delete other buffers";
      }

      #------------------------------------------------------------------------
      # RENAME (LSP-aware file rename)
      #------------------------------------------------------------------------
      {
        key = "<leader>cR";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.rename.rename_file() end";
        options.desc = "Rename file";
      }

      #------------------------------------------------------------------------
      # TERMINAL
      #------------------------------------------------------------------------
      {
        key = "<c-/>";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.terminal() end";
        options.desc = "Toggle terminal";
      }
      {
        key = "<c-/>";
        mode = "t";
        options.silent = true;
        action = "<cmd>close<cr>";
        options.desc = "Hide terminal";
      }

      #------------------------------------------------------------------------
      # SCRATCH
      #------------------------------------------------------------------------
      {
        key = "<leader>.";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.scratch() end";
        options.desc = "Toggle scratch buffer";
      }
      {
        key = "<leader>S";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.scratch.select() end";
        options.desc = "Select scratch buffer";
      }

      #------------------------------------------------------------------------
      # ZEN / ZOOM
      #------------------------------------------------------------------------
      {
        key = "<leader>z";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.zen() end";
        options.desc = "Zen mode";
      }
      {
        key = "<leader>Z";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.zen.zoom() end";
        options.desc = "Zoom mode";
      }

      #------------------------------------------------------------------------
      # TOGGLES
      #------------------------------------------------------------------------
      {
        key = "<leader>us";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.toggle.option('spell', { name = 'Spelling' }):toggle() end";
        options.desc = "Toggle spelling";
      }
      {
        key = "<leader>uw";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.toggle.option('wrap', { name = 'Wrap' }):toggle() end";
        options.desc = "Toggle wrap";
      }
      {
        key = "<leader>uL";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.toggle.option('relativenumber', { name = 'Relative Numbers' }):toggle() end";
        options.desc = "Toggle relative numbers";
      }
      {
        key = "<leader>ud";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.toggle.diagnostics():toggle() end";
        options.desc = "Toggle diagnostics";
      }
      {
        key = "<leader>uh";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.toggle.inlay_hints():toggle() end";
        options.desc = "Toggle inlay hints";
      }
      {
        key = "<leader>uD";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.toggle.dim():toggle() end";
        options.desc = "Toggle dim";
      }
      {
        key = "<leader>ui";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.toggle.indent():toggle() end";
        options.desc = "Toggle indent guides";
      }
      {
        key = "<leader>un";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.toggle.option('number', { name = 'Line Numbers' }):toggle() end";
        options.desc = "Toggle line numbers";
      }
      {
        key = "<leader>uT";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.toggle.treesitter():toggle() end";
        options.desc = "Toggle treesitter";
      }

      #------------------------------------------------------------------------
      # NOTIFICATIONS
      #------------------------------------------------------------------------
      {
        key = "<leader>nn";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.notifier.show_history() end";
        options.desc = "Notification history";
      }
      {
        key = "<leader>nd";
        mode = "n";
        options.silent = true;
        action.__raw = "function() Snacks.notifier.hide() end";
        options.desc = "Dismiss notifications";
      }
    ];
  };
}
