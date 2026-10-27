-- Run from any directory after installing the locked Neovim plugins:
-- nvim --headless -u NONE -i NONE -l tests/nvim-markview.lua
local repository = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
for _, plugin in ipairs { 'markview.nvim', 'markview-smart-tables.nvim', 'telescope.nvim', 'plenary.nvim' } do
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

local function open(name, filetype, lines)
  lines = lines or contents
  local path = directory .. '/' .. name
  vim.fn.writefile(lines, path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  assert(vim.bo.filetype == filetype, 'Unexpected filetype for ' .. name)
  vim.api.nvim_win_set_cursor(0, { #lines, 0 })
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

local function table_rendering(buffer)
  local result = { hidden_rows = 0, lines = 0, width = 0, text = '' }
  local namespace = vim.api.nvim_get_namespaces()['markview/markdown']
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buffer, namespace, 0, -1, { details = true })) do
    local detail = mark[4]
    if detail.conceal_lines ~= nil and detail.conceal_lines ~= false then
      result.hidden_rows = result.hidden_rows + 1
    end
    for _, line in ipairs(detail.virt_lines or {}) do
      local chunks = {}
      for _, chunk in ipairs(line) do
        chunks[#chunks + 1] = chunk[1]
      end
      local text = table.concat(chunks)
      result.lines = result.lines + 1
      result.width = math.max(result.width, vim.fn.strdisplaywidth(text))
      result.text = result.text .. text .. '\n'
    end
  end
  return result
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
  assert(not vim.wo.concealcursor:find('n', 1, true), 'Hybrid mode must reveal the source under the normal-mode cursor')
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

  -- Wide tables must fit the window without turning wrapping off for prose.
  vim.wo.wrap = true
  local table_source = {
    '# Tables',
    '',
    'Ordinary prose still wraps. ' .. string.rep('This paragraph stays readable. ', 10),
    '',
    '| Kind | Description |',
    '| --- | --- |',
    '| `cache` | **Shared** cache with COUNT_SENTINEL and ' .. string.rep('distributed locking and counters. ', 12) .. ' |',
    '',
    'Cursor outside the table.',
  }
  local wide = open('wide.md', 'markdown', table_source)
  assert(not state.get_buffer_state(wide, false).enable, 'Table preview must remain off by default')
  vim.api.nvim_set_current_buf(second)
  vim.cmd 'Markview Enable'
  select_buffer(wide)
  local rendered = table_rendering(wide)
  local budget = math.floor((vim.api.nvim_win_get_width(0) - vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff) * 0.9)
  assert(vim.wo.wrap, 'Rendering tables must not disable wrapping')
  assert(rendered.hidden_rows == 3, 'Hidden-buffer tables were not refreshed on Telescope entry')
  assert(rendered.lines > 5, 'Wide table cells did not wrap into additional lines')
  assert(rendered.width <= budget, 'Fitted table exceeds the available window width')
  assert(rendered.text:find('COUNT_SENTINEL', 1, true), 'Fitted table lost its cell contents')

  -- Moving onto a fitted table must reveal its real, editable source.
  vim.api.nvim_win_set_cursor(0, { 7, 2 })
  vim.cmd 'Markview render'
  assert(table_rendering(wide).hidden_rows == 0, 'Hybrid navigation did not reveal the table source')
  vim.api.nvim_win_set_cursor(0, { #table_source, 0 })
  vim.cmd 'Markview render'
  assert(table_rendering(wide).hidden_rows == 3, 'Moving off the table did not restore fitted rendering')
  vim.cmd 'Markview disable'
  assert(table_rendering(wide).hidden_rows == 0, 'Disabled table preview still conceals source lines')
  vim.cmd 'Markview enable'
  assert(table_rendering(wide).hidden_rows == 3, 'Re-enabling table preview did not restore rendering')
  assert(vim.wo.wrap, 'Table navigation or preview toggles changed wrapping')
  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(wide, 0, -1, false), table_source), 'Table rendering changed buffer contents')
  assert(vim.deep_equal(vim.fn.readfile(directory .. '/wide.md'), table_source), 'Table rendering changed file contents')

  -- Stopping Markview must not let our window hook change options either.
  vim.api.nvim_set_current_buf(first)
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
print 'Markview/Telescope hidden-buffer toggles, wrapped tables, hybrid navigation, split preview, and stop checks passed.'
