-- Run from any directory after installing the locked Neovim plugins:
-- nvim --headless -u NONE -i NONE -l tests/nvim-markview.lua
local repository = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
for _, plugin in ipairs { 'markview.nvim', 'telescope.nvim', 'plenary.nvim' } do
  local path = vim.fn.stdpath 'data' .. '/lazy/' .. plugin
  assert(vim.fn.isdirectory(path) == 1, 'Missing installed plugin: ' .. plugin)
  vim.opt.rtp:prepend(path)
end
vim.cmd 'filetype plugin on'
vim.o.lines = 50
vim.o.columns = 160
vim.o.swapfile = false
require('telescope').setup { defaults = { initial_mode = 'normal' } }

local markview_spec
for _, spec in ipairs(dofile(repository .. '/.config/nvim/lua/custom/plugins/ui.lua')) do
  if spec[1] == 'OXY2DEV/markview.nvim' then
    markview_spec = spec
  end
end
assert(markview_spec, 'Markview configuration not found')
markview_spec.init()
vim.cmd 'runtime plugin/markview.lua'
if markview_spec.config then
  markview_spec.config(nil, markview_spec.opts)
else
  require('markview').setup(markview_spec.opts)
end

local directory = vim.fn.tempname()
vim.fn.mkdir(directory, 'p')
local state = require 'markview.state'
local contents = { '## Heading', '', '- Keep `code` and **bold**.', '', 'Cursor here' }

local function open(name, filetype)
  local path = directory .. '/' .. name
  vim.fn.writefile(contents, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  assert(vim.bo.filetype == filetype, 'Unexpected filetype for ' .. name)
  return vim.api.nvim_get_current_buf()
end

local function select_buffer(buffer)
  local prompt
  require('telescope.builtin').buffers {
    previewer = false,
    default_text = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buffer), ':t'),
    attach_mappings = function(buf)
      prompt = buf
      return true
    end,
  }
  assert(
    vim.wait(2000, function()
      local entry = prompt and require('telescope.actions.state').get_current_picker(prompt):get_selection()
      return entry and entry.bufnr == buffer
    end),
    'Telescope did not find the test buffer'
  )
  require('telescope.actions').select_default(prompt)
  assert(vim.api.nvim_get_current_buf() == buffer, 'Telescope did not switch buffers')
end

local function conceal_marks(buffer)
  local count = 0
  for name, namespace in pairs(vim.api.nvim_get_namespaces()) do
    if name:match '^markview/' then
      for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buffer, namespace, 0, -1, { details = true })) do
        if mark[4].conceal ~= nil then
          count = count + 1
        end
      end
    end
  end
  return count
end

local ok, err = xpcall(function()
  local first = open('first.md', 'markdown')
  local second = open('second.md', 'markdown')
  assert(not state.get_buffer_state(first, false).enable, 'Preview must remain off by default')
  assert(vim.wo.conceallevel == 0)

  -- The configured mapping toggles ALL attached buffers, including hidden ones.
  vim.cmd 'Markview Toggle'
  assert(state.get_buffer_state(first, false).enable)
  assert(conceal_marks(first) > 0, 'Hidden Markdown must already have render decorations')
  select_buffer(first)
  assert(vim.wo.conceallevel == 3, 'Enabled hidden Markdown lost conceal after Telescope selection')
  assert(vim.wo.concealcursor:find('n', 1, true), 'Normal-mode cursor line must also conceal markup')
  assert(conceal_marks(first) > 0)
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(first, 0, -1, false), contents), 'Rendering changed file contents')

  -- The reverse transition must not leave a disabled buffer concealed.
  vim.cmd 'Markview Toggle'
  select_buffer(second)
  assert(not state.get_buffer_state(second, false).enable)
  assert(vim.wo.conceallevel == 0, 'Disabled hidden Markdown retained conceal')
  assert(conceal_marks(second) == 0, 'Disabled Markdown retained render decorations')

  -- Non-Markdown buffers must keep their own window settings.
  local plain = open('plain.txt', 'text')
  vim.wo.conceallevel = 1
  vim.wo.concealcursor = 'i'
  vim.api.nvim_set_current_buf(first)
  vim.api.nvim_set_current_buf(plain)
  assert(vim.wo.conceallevel == 1 and vim.wo.concealcursor == 'i')

  -- Enabled buffers also need their settings in a newly created window.
  vim.api.nvim_set_current_buf(first)
  vim.cmd 'Markview Toggle'
  local original_window = vim.api.nvim_get_current_win()
  vim.cmd 'new'
  vim.wo.conceallevel = 0
  vim.api.nvim_set_current_buf(second)
  assert(vim.wo.conceallevel == 3, 'New window did not restore enabled Markdown conceal')
  vim.api.nvim_win_close(0, true)
  vim.api.nvim_set_current_win(original_window)

  -- Split preview deliberately leaves its source raw.
  vim.cmd 'Markview splitOpen'
  local source_window = vim.fn.win_findbuf(first)[1]
  vim.api.nvim_set_current_win(source_window)
  vim.api.nvim_set_current_buf(plain)
  vim.api.nvim_set_current_buf(first)
  assert(vim.wo.conceallevel == 0, 'Split preview source must remain raw')
  vim.cmd 'Markview splitClose'

  -- Stopping Markview must not let our window hook change options either.
  vim.cmd 'Markview Stop'
  vim.wo.conceallevel = 1
  vim.api.nvim_set_current_buf(second)
  vim.api.nvim_set_current_buf(first)
  assert(vim.wo.conceallevel == 1, 'Stopped Markview changed window options')
end, debug.traceback)
vim.fn.delete(directory, 'rf')
if not ok then
  error(err)
end
print 'Markview/Telescope hidden-buffer toggles, raw mode, window entry, split preview, and stop checks passed.'
