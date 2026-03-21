return {
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = 'Diffview: open diff' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'Diffview: file history' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = 'Diffview: repo history' },
      { '<leader>gc', '<cmd>DiffviewClose<cr>', desc = 'Diffview: close' },
    },
    opts = {},
  },
}
