-- Seamless Neovim split and tmux pane navigation without a plugin.
local M = {}

local tmux_directions = {
  h = '-L',
  j = '-D',
  k = '-U',
  l = '-R',
}

---Return the current and adjacent Neovim window numbers for a direction.
---@param direction 'h'|'j'|'k'|'l'
---@return integer current
---@return integer? neighbor
local function windows(direction)
  local current = vim.fn.winnr()
  local neighbor = vim.fn.winnr(direction)
  return current, neighbor ~= current and neighbor or nil
end

---Run a tmux command without shell interpolation.
---@param arguments string[]
local function run_tmux(arguments)
  if not vim.env.TMUX then
    return
  end

  local command = { 'tmux' }
  vim.list_extend(command, arguments)
  vim.fn.jobstart(command, { detach = true })
end

---Move within Neovim, crossing into tmux at the outer editor boundary.
---@param direction 'h'|'j'|'k'|'l'
function M.navigate(direction)
  local _, neighbor = windows(direction)
  if neighbor then
    vim.cmd('wincmd ' .. direction)
  else
    run_tmux { 'select-pane', tmux_directions[direction] }
  end
end

---Resize toward a Neovim split, or resize the enclosing tmux pane at an edge.
---@param direction 'h'|'j'|'k'|'l'
function M.resize(direction)
  local current, neighbor = windows(direction)
  if not neighbor then
    local amount = (direction == 'h' or direction == 'l') and '3' or '2'
    run_tmux { 'resize-pane', tmux_directions[direction], amount }
    return
  end

  -- Move the separator in the requested direction so Neovim and tmux use the
  -- same "grow toward h/j/k/l" semantics on either side of the boundary.
  if direction == 'h' then
    vim.fn.win_move_separator(neighbor, -3)
  elseif direction == 'l' then
    vim.fn.win_move_separator(current, 3)
  elseif direction == 'k' then
    vim.fn.win_move_statusline(neighbor, -2)
  else
    vim.fn.win_move_statusline(current, 2)
  end
end

function M.setup()
  local labels = {
    h = 'left',
    j = 'lower',
    k = 'upper',
    l = 'right',
  }

  for direction, label in pairs(labels) do
    vim.keymap.set('n', '<C-' .. direction .. '>', function()
      M.navigate(direction)
    end, { desc = 'Move focus to the ' .. label .. ' split or tmux pane' })

    vim.keymap.set('n', '<C-S-' .. direction .. '>', function()
      M.resize(direction)
    end, { desc = 'Resize the ' .. label .. ' split or tmux pane' })
  end
end

return M
