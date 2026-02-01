return {
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
    config = function()
      require('oil').setup {
        default_file_explorer = true,
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        view_options = {
          show_hidden = true,
          natural_order = true,
        },
        win_options = {
          wrap = true,
        },
      }

      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
      vim.keymap.set('n', '<leader>e', '<CMD>Oil<CR>', { desc = 'Oil explorer' })
    end,
  },

  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree', -- Only load when explicitly called
    keys = {
      { '<leader>E', '<cmd>Neotree toggle<cr>', desc = 'NeoTree (secondary)' },
    },
    opts = {
      filesystem = {
        hijack_netrw_behavior = 'disabled', -- Let oil handle netrw
        filtered_items = {
          visible = true, -- This is what you want: show hidden files by default
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },
}
