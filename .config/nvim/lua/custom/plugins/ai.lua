return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        panel = {
          enabled = true,
          auto_refresh = false,
          keymap = {
            jump_prev = '[[',
            jump_next = ']]',
            accept = '<CR>',
            refresh = 'gr',
            open = '<M-CR>',
          },
          layout = {
            position = 'bottom', -- | top | left | right
            ratio = 0.4,
          },
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            -- Copilot defaults to <M-l>. It is disabled here because Blink owns <Tab>
            -- and dispatches to Copilot only when a suggestion is visible. Giving both
            -- plugins their own Tab mapping would make behavior depend on load order.
            -- Set this to <M-l> and remove Blink's custom Tab function to use separate keys.
            accept = false,
            accept_word = false,
            accept_line = false,
            next = '<M-]>',
            prev = '<M-[>',
            dismiss = '<C-]>',
          },
        },
        filetypes = {
          yaml = false,
          markdown = false,
          help = false,
          gitcommit = false,
          gitrebase = false,
          hgcommit = false,
          svn = false,
          cvs = false,
          ['.'] = false,
        },
        copilot_node_command = 'node', -- Node.js version must be > 16.x
        server_opts_overrides = {},
      }

      -- hide_during_completion defaults to true, but Blink uses a custom menu rather
      -- than Neovim's popup menu. Copilot documents these User events for Blink so its
      -- ghost text does not overlap completion items. Remove these hooks only if inline
      -- suggestions are disabled or another integration manages the buffer flag.
      vim.api.nvim_create_autocmd('User', {
        pattern = 'BlinkCmpMenuOpen',
        callback = function()
          vim.b.copilot_suggestion_hidden = true
        end,
      })

      -- Clear the buffer-local flag as soon as Blink closes; otherwise Copilot would
      -- remain hidden in this buffer. This is the matching half of the menu-open hook.
      vim.api.nvim_create_autocmd('User', {
        pattern = 'BlinkCmpMenuClose',
        callback = function()
          vim.b.copilot_suggestion_hidden = false
        end,
      })
    end,
  },
}
