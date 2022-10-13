return require('packer').startup(function(use)

  -- Plugin manger
  use 'wbthomason/packer.nvim'

  -- Colour Scheme
  use { "EdenEast/nightfox.nvim",
    config = function()
      vim.cmd [[colorscheme carbonfox]]
    end, }

  -- Language Servers
  use(
    {
      'williamboman/mason.nvim',
      config = function()
        require("mason").setup()
        require("mason-lspconfig").setup()
      end,
      requires = {
        'williamboman/mason-lspconfig.nvim',
        'neovim/nvim-lspconfig'
      }
    },
    'williamboman/mason-lspconfig.nvim',
    'neovim/nvim-lspconfig'
  )

  use {
    "jose-elias-alvarez/null-ls.nvim",
    config = function()
      require("configs.nullls")
    end,
  }

  use {
    'hrsh7th/nvim-cmp',
    config = function()
      require('configs.cmp-nvim')
    end,
  }

  -- LSP completion source
  use {
    'hrsh7th/cmp-nvim-lsp',
  }

  -- Buffer completion source
  use {
    'hrsh7th/cmp-buffer',
    after = 'nvim-cmp',
  }

  -- Path completion source
  use {
    'hrsh7th/cmp-path',
    after = 'nvim-cmp',
  }

  -- Command line completion source
  use {
    'hrsh7th/cmp-cmdline',
    after = 'nvim-cmp',
  }

  -- LSP signature
  use {
    'ray-x/lsp_signature.nvim',
    after = 'nvim-cmp',
  }

  -- linting engine
  use 'dense-analysis/ale'

  -- Snippet engine
  use 'hrsh7th/vim-vsnip'

  -- Snippet completion source
  use {
    'hrsh7th/cmp-vsnip',
    after = 'nvim-cmp',
  }

  -- Syntax highlighting
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    event = 'BufRead',
    cmd = {
      'TSInstall',
      'TSInstallInfo',
      'TSInstallSync',
      'TSUninstall',
      'TSUpdate',
      'TSUpdateSync',
      'TSDisableAll',
      'TSEnableAll',
    },
    config = function()
      require('configs.treesitter')
    end,
    requires = {
      {
        -- Parenthesis highlighting
        'p00f/nvim-ts-rainbow',
        after = 'nvim-treesitter',
      },
      {
        'haringsrob/nvim_context_vt',
        after = 'nvim-treesitter',
      }
    },
  }

  -- Auto Pairs (Brackets and Stuff)
  use 'jiangmiao/auto-pairs'

  -- Git Messenger(Shows origin of code)
  use 'rhysd/git-messenger.vim'
  use({
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup({
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
          delay = 500,
          ignore_whitespace = false,
        },
      })
    end
  })

  -- nerdy shit
  use("ThePrimeagen/git-worktree.nvim")

  use {
    'ThePrimeagen/harpoon',
    requires = {
      'nvim-lua/plenary.nvim',
    },
  }

  -- Development Plugins
  use 'pangloss/vim-javascript' -- Syntax highlighting and improved indentation for JS
  use 'tpope/vim-surround' -- Replacing surrounding stuff
  use 'mg979/vim-visual-multi' -- Edit multiple lines at once
  use {
    'b3nj5m1n/kommentary',
    config = function()
      require('configs.kommentary')
    end
  } -- Commentsss


  -- Notifications
  use {
    'rcarriga/nvim-notify',
    config = function()
      vim.notify = require("notify")
    end
  }

  -- Highlight colours
  use {
    'norcalli/nvim-colorizer.lua',
    config = function()
      require('configs.colorizer')
    end,
    after = 'nvim-treesitter'
  }

  -- File finder
  use {
    'nvim-telescope/telescope.nvim',
    config = function()
      require('configs.telescope')
    end
  }

  -- Bufferline
  use {
    'akinsho/bufferline.nvim',
    tag = "v2.*",
    requires = 'kyazdani42/nvim-web-devicons',
    config = function()
      require('configs.bufferline')
    end
  }

  -- Statusline
  use {
    'nvim-lualine/lualine.nvim',
    after = 'bufferline.nvim',
    config = function()
      require('configs.lualine')
    end,
  }

    -- File Explorer
  use({
    "kyazdani42/nvim-tree.lua",
    config = function()
      require("configs.tree")
    end,
  })

  -- Better Colors for various elements
  use 'folke/trouble.nvim'

  -- Icons
  use 'kyazdani42/nvim-web-devicons'

  -- Terminal
  use {
    "akinsho/toggleterm.nvim",
    tag = '*',
    config = function()
      require("toggleterm").setup()

      function _G.set_terminal_keymaps()
        local opts = { noremap = true }
        vim.api.nvim_buf_set_keymap(0, 't', '<A-t>', [[<Cmd>ToggleTerm<CR>]], opts)
      end

      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

    end
  }

  use 'github/copilot.vim'
  use 'editorconfig/editorconfig-vim'
  use {
    "folke/which-key.nvim",
    config = function()
      require('configs.whichkey')
    end
  }
end)
