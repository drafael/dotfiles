return {
  {
    'nvim-tree/nvim-web-devicons',
    lazy = false, -- Load immediately on startup
    priority = 1000, -- Load before other plugins
    config = function()
      require('nvim-web-devicons').setup {
        default = true,
      }
    end,
  },

  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {
      indent = {
        char = '┊',
      },
      scope = {
        enabled = false,
      },
      exclude = {
        filetypes = {
          'help',
          'alpha',
          'dashboard',
          'neo-tree',
          'Trouble',
          'lazy',
          'mason',
          'notify',
          'toggleterm',
          'lazyterm',
        },
        buftypes = { 'terminal', 'nofile' },
      },
    },
    config = function(_, opts)
      require('ibl').setup(opts)

      -- Custom keymaps
      vim.keymap.set('n', '<leader>ti', '<cmd>IBLToggle<cr>', { desc = 'Toggle indent guides' })
      vim.keymap.set('n', '<leader>ts', '<cmd>IBLToggleScope<cr>', { desc = 'Toggle scope highlight' })
    end,
  },

  {
    'OXY2DEV/markview.nvim',
    lazy = false,
    init = function()
      -- Set alpha to 0 so backgrounds match Normal (no visible tint)
      vim.g.markview_alpha = 0
      vim.g.markview_code_alpha = 0
      vim.g.markview_inline_code_alpha = 0
    end,
    opts = {
      preview = {
        enable = false,
        filetypes = { 'markdown', 'asciidoc' },
      },
    },
    keys = {
      { '<leader>tm', '<cmd>Markview Toggle<cr>', desc = 'Toggle Markview' },
    },
  },

  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'auto', -- auto, latte, frappe, macchiato, mocha
        background = { -- :h background
          light = 'latte',
          dark = 'frappe',
        },
        float = {
          transparent = false, -- enable transparent floating windows
          solid = false, -- use solid styling for floating windows, see |winborder|
        },
        transparent_background = false,
        show_end_of_buffer = false,
        term_colors = false,
        dim_inactive = {
          enabled = false,
          shade = 'dark',
          percentage = 0.15,
        },
        no_italic = true,
        no_bold = false,
        no_underline = false,
        styles = {
          comments = { 'italic' },
          conditionals = { 'italic' },
          loops = {},
          functions = {},
          keywords = {},
          strings = {},
          variables = {},
          numbers = {},
          booleans = {},
          properties = {},
          types = {},
          operators = {},
        },
        color_overrides = {},
        custom_highlights = {},
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          notify = false,
          diffview = true,
          mini = {
            enabled = true,
            indentscope_color = '',
          },
        },
      }

      -- Set the colorscheme
      vim.cmd.colorscheme 'catppuccin'
    end,
  },

  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      -- Nerd Fonts provides three Copilot glyph variants. These match the
      -- copilot-lualine defaults: normal, disabled, and warning/auth required.
      -- Keeping all states in the Copilot icon family is less noisy than adding text.
      local copilot_icons = {
        enabled = '',
        disabled = '',
        auth_required = '',
      }
      local copilot_authenticated = false
      local copilot_auth_check_pending = false

      -- Keep the component local instead of adding copilot-lualine: the external
      -- component reports more activity states than this status needs. package.loaded
      -- also preserves Copilot's InsertEnter lazy loading; require() here would load it
      -- as soon as lualine renders.
      local function copilot_status()
        local client = package.loaded['copilot.client']
        if not client or client.is_disabled() or not client.initialized then
          return copilot_icons.disabled
        end

        -- Copilot caches successful auth checks for five minutes and failed checks
        -- for 30 seconds. Limit calls while its asynchronous check is in flight, then
        -- redraw the statusline when the result arrives. :Copilot auth is the recovery
        -- command when this component shows the Copilot warning icon.
        if not copilot_auth_check_pending then
          local ok, auth = pcall(require, 'copilot.auth')
          if ok then
            copilot_auth_check_pending = true
            local check_ok, authenticated = pcall(auth.is_authenticated, function(err)
              copilot_auth_check_pending = false
              copilot_authenticated = not err and auth.is_authenticated() or false
              vim.schedule(function()
                vim.cmd.redrawstatus()
              end)
            end)

            if check_ok then
              copilot_authenticated = authenticated
            else
              copilot_auth_check_pending = false
            end

            -- A cached false result does not invoke the callback. Release the guard
            -- so lualine can re-check after Copilot's cache expires.
            vim.defer_fn(function()
              copilot_auth_check_pending = false
            end, 5000)
          end
        end

        if not copilot_authenticated then
          return copilot_icons.auth_required
        end

        -- "Enabled" is buffer-specific. Copilot may be authenticated globally but
        -- disabled here by filetype rules or :Copilot detach. The alternative is to
        -- report only the global client state and omit buf_is_attached().
        if client.buf_is_attached(0) then
          return copilot_icons.enabled
        end
        return copilot_icons.disabled
      end

      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '', right = '' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = false,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { 'filename' },
          -- Put Copilot at the end of the right-hand metadata section, before
          -- progress and location. Use :Copilot status when an icon needs explanation.
          lualine_x = { 'encoding', 'fileformat', 'filetype', copilot_status },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {},
      }
    end,
  },
}
