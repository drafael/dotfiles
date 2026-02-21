-- Indentation/formatting priority chain (first match wins):
--   1. .editorconfig        Built-in Neovim support (vim.g.editorconfig = true), fires on BufReadPost
--   2. IntelliJ IDEA        .idea/codeStyles/Project.xml or .idea/codeStyleSettings.xml
--   3. Eclipse              .settings/org.eclipse.jdt.core.prefs (and siblings)
--   4. VS Code / Cursor     .vscode/settings.json
--   5. Language defaults    Common conventions per filetype
--   6. Infer from codebase  guess-indent.nvim (already ran on BufReadPost, we don't override)

local M = {}

-- Cache: (project_root .. ':' .. filetype) -> settings table | false
local _cache = {}

-- IntelliJ: Neovim filetype → language ID used in <codeStyleSettings language="…">
local _intellij_lang = {
  java            = 'JAVA',
  kotlin          = 'kotlin',
  groovy          = 'Groovy',
  javascript      = 'JavaScript',
  javascriptreact = 'JavaScript',
  typescript      = 'TypeScript',
  typescriptreact = 'TypeScript',
  html            = 'HTML',
  css             = 'CSS',
  xml             = 'XML',
  python          = 'Python',
  go              = 'go',
  rust            = 'Rust',
  php             = 'PHP',
  ruby            = 'ruby',
  scala           = 'Scala',
}

-- Eclipse prefs filename per Neovim filetype
local _eclipse_prefs = {
  java            = 'org.eclipse.jdt.core.prefs',
  javascript      = 'org.eclipse.wst.jsdt.core.prefs',
  javascriptreact = 'org.eclipse.wst.jsdt.core.prefs',
  php             = 'org.eclipse.php.core.prefs',
}

-- Language-specific defaults (priority 5)
local _lang_defaults = {
  -- JVM languages
  java            = { tabstop = 4, shiftwidth = 4, expandtab = true },
  kotlin          = { tabstop = 4, shiftwidth = 4, expandtab = true },
  groovy          = { tabstop = 4, shiftwidth = 4, expandtab = true },
  scala           = { tabstop = 2, shiftwidth = 2, expandtab = true },
  -- Systems
  c               = { tabstop = 4, shiftwidth = 4, expandtab = true },
  cpp             = { tabstop = 4, shiftwidth = 4, expandtab = true },
  rust            = { tabstop = 4, shiftwidth = 4, expandtab = true },
  go              = { tabstop = 4, shiftwidth = 4, expandtab = false }, -- tabs by convention
  swift           = { tabstop = 4, shiftwidth = 4, expandtab = true },
  -- Scripting
  python          = { tabstop = 4, shiftwidth = 4, expandtab = true },
  ruby            = { tabstop = 2, shiftwidth = 2, expandtab = true },
  php             = { tabstop = 4, shiftwidth = 4, expandtab = true },
  lua             = { tabstop = 2, shiftwidth = 2, expandtab = true },
  -- Web / JS
  javascript      = { tabstop = 2, shiftwidth = 2, expandtab = true },
  javascriptreact = { tabstop = 2, shiftwidth = 2, expandtab = true },
  typescript      = { tabstop = 2, shiftwidth = 2, expandtab = true },
  typescriptreact = { tabstop = 2, shiftwidth = 2, expandtab = true },
  html            = { tabstop = 2, shiftwidth = 2, expandtab = true },
  css             = { tabstop = 2, shiftwidth = 2, expandtab = true },
  scss            = { tabstop = 2, shiftwidth = 2, expandtab = true },
  -- Data / config
  json            = { tabstop = 2, shiftwidth = 2, expandtab = true },
  yaml            = { tabstop = 2, shiftwidth = 2, expandtab = true },
  xml             = { tabstop = 2, shiftwidth = 2, expandtab = true },
  toml            = { tabstop = 2, shiftwidth = 2, expandtab = true },
  -- Shell
  sh              = { tabstop = 2, shiftwidth = 2, expandtab = true },
  bash            = { tabstop = 2, shiftwidth = 2, expandtab = true },
  zsh             = { tabstop = 2, shiftwidth = 2, expandtab = true },
}

-- ── Helpers ────────────────────────────────────────────────────────────────

local function readable(path) return vim.fn.filereadable(path) == 1 end
local function isdir(path)    return vim.fn.isdirectory(path) == 1 end

-- Inspect which indent properties the built-in EditorConfig handler set for this
-- buffer.  Neovim stores the applied .editorconfig properties in vim.b.editorconfig.
-- Returns: has_size (a *numeric* indent_size or tab_width was set),
--          has_style (indent_style was set)
--
-- IMPORTANT: indent_size = "tab" means "use tab_width".  When tab_width is also
-- absent the actual width is unresolved (Neovim leaves tabstop at its default 8).
-- We must NOT treat that as "size is handled".
local function editorconfig_indent_coverage(bufnr)
  local ec = vim.b[bufnr].editorconfig
  if not ec then return false, false end

  local has_style = ec.indent_style ~= nil

  -- tab_width always gives us a concrete number
  if ec.tab_width ~= nil then return true, has_style end

  -- indent_size = "tab" is NOT a concrete size — it defers to tab_width (which is absent here)
  if ec.indent_size ~= nil and tostring(ec.indent_size) ~= 'tab' then
    return true, has_style
  end

  return false, has_style
end

-- Walk up from start_dir to find the project root (VCS/IDE marker)
local function project_root(start_dir)
  local dir = start_dir
  while true do
    for _, m in ipairs { '.git', '.idea', '.vscode', '.hg', '.svn' } do
      if isdir(dir .. '/' .. m) or readable(dir .. '/' .. m) then
        return dir
      end
    end
    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir then return start_dir end
    dir = parent
  end
end

-- Read file to a single string, returns nil on failure
local function read_file(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and table.concat(lines, '\n') or nil
end

-- ── Priority 2: IntelliJ IDEA ─────────────────────────────────────────────

-- Extract <option name="KEY" value="VAL"/> from an XML fragment
local function xml_opt(fragment, key)
  return fragment:match('<option%s+name="' .. key .. '"%s+value="([^"]+)"')
      or fragment:match('<option%s+value="([^"]+)"%s+name="' .. key .. '"')
end

-- Extract inner text of <TAG …>…</TAG>  (first match, non-greedy)
local function xml_inner(content, tag)
  return content:match('<' .. tag .. '[^>]*>(.-)</' .. tag .. '>')
end

-- IntelliJ stores indent settings in several possible locations (checked in order):
--   1. <codeStyleSettings language="JAVA"> → <indentOptions> … </indentOptions>
--      This is the PRIMARY per-language indent config in modern IntelliJ.
--   2. <code_scheme> top-level <option name="INDENT_SIZE">, <option name="TAB_SIZE">
--      These are the GLOBAL defaults (apply to all languages without a specific block).
--   3. <ADDITIONAL_INDENT_OPTIONS fileType="java"> (legacy, ignored — often stale)
--
-- We must NOT do a flat regex search on the entire document because that picks up
-- values from ADDITIONAL_INDENT_OPTIONS or other language blocks.

local function parse_intellij(root, ft)
  for _, rel in ipairs { '.idea/codeStyles/Project.xml', '.idea/codeStyleSettings.xml' } do
    local path = root .. '/' .. rel
    if not readable(path) then goto next_file end

    local content = read_file(path)
    if not content then goto next_file end

    local indent_size, use_tab

    -- 1. Per-language: <codeStyleSettings language="JAVA"> → <indentOptions>
    local lang_id = _intellij_lang[ft]
    if lang_id then
      local lang_block = content:match(
        '<codeStyleSettings language="' .. lang_id .. '">(.-)</codeStyleSettings>'
      )
      if lang_block then
        local indent_opts = xml_inner(lang_block, 'indentOptions')
        if indent_opts then
          indent_size = tonumber(xml_opt(indent_opts, 'INDENT_SIZE'))
                     or tonumber(xml_opt(indent_opts, 'TAB_SIZE'))
          local ut = xml_opt(indent_opts, 'USE_TAB_CHARACTER')
          if ut then use_tab = (ut == 'true') end
        end
        -- USE_TAB_CHARACTER can also be directly in codeStyleSettings (outside indentOptions)
        if use_tab == nil then
          local ut = xml_opt(lang_block, 'USE_TAB_CHARACTER')
          if ut then use_tab = (ut == 'true') end
        end
      end
    end

    -- 2. Global defaults from <code_scheme> top-level options (direct children only).
    --    Extract the <code_scheme> content but EXCLUDE nested sections to avoid
    --    picking up values from ADDITIONAL_INDENT_OPTIONS or language blocks.
    if not indent_size then
      local scheme = xml_inner(content, 'code_scheme')
      if scheme then
        -- Strip all nested elements (anything with children) to get only top-level options
        local top_level = scheme
          :gsub('<codeStyleSettings.-</codeStyleSettings>', '')
          :gsub('<ADDITIONAL_INDENT_OPTIONS.-</ADDITIONAL_INDENT_OPTIONS>', '')
          :gsub('<JavaCodeStyleSettings.-</JavaCodeStyleSettings>', '')
          :gsub('<ScalaCodeStyleSettings.-</ScalaCodeStyleSettings>', '')
          :gsub('<[%w]+CodeStyleSettings.-</[%w]+CodeStyleSettings>', '')
        indent_size = tonumber(xml_opt(top_level, 'INDENT_SIZE'))
                   or tonumber(xml_opt(top_level, 'TAB_SIZE'))
        if use_tab == nil then
          local ut = xml_opt(top_level, 'USE_TAB_CHARACTER')
          if ut then use_tab = (ut == 'true') end
        end
      end
    end

    -- If we found USE_TAB_CHARACTER but no explicit size, use IntelliJ's default (4)
    if use_tab ~= nil and not indent_size then
      indent_size = 4
    end

    if indent_size then
      return { tabstop = indent_size, shiftwidth = indent_size, expandtab = not use_tab }
    end

    ::next_file::
  end
end

-- ── Priority 3: Eclipse ───────────────────────────────────────────────────

local function parse_eclipse(root, ft)
  -- Build ordered candidate list: language-specific first, then generic
  local candidates = {}
  if _eclipse_prefs[ft] then
    candidates[#candidates + 1] = root .. '/.settings/' .. _eclipse_prefs[ft]
  end
  candidates[#candidates + 1] = root .. '/.settings/org.eclipse.core.runtime.prefs'

  local seen = {}
  for _, path in ipairs(candidates) do
    if not seen[path] and readable(path) then
      seen[path] = true
      local tab_size, use_tabs
      for _, line in ipairs(vim.fn.readfile(path)) do
        local key, val = line:match('^([^=]+)=(.+)$')
        if key and val then
          key, val = vim.trim(key), vim.trim(val)
          -- JDT tabulation settings
          if     key:find('tabulation%.size$') or key:find('indentation%.size$') then
            tab_size = tonumber(val)
          elseif key:find('tabulation%.char$') then
            use_tabs = (val == 'tab')
          end
        end
      end
      if tab_size then
        return { tabstop = tab_size, shiftwidth = tab_size, expandtab = not use_tabs }
      end
    end
  end
end

-- ── Priority 4: VS Code / Cursor ──────────────────────────────────────────

local function parse_vscode(root, ft)
  local path = root .. '/.vscode/settings.json'
  if not readable(path) then return nil end

  local content = read_file(path)
  if not content then return nil end

  -- Strip // line comments (JSONC format used by VS Code)
  content = content:gsub('//[^\n]*', '')

  -- If VS Code is set to auto-detect, defer to guess-indent (priority 6)
  if content:match('"editor%.detectIndentation"%s*:%s*true') then return nil end

  -- Check per-language override block first: "[java]": { "editor.tabSize": 4 }
  local lang_block = content:match('%["' .. ft .. '"%]%s*:%s*(%b{})')
  local tab_size  = lang_block and lang_block:match('"editor%.tabSize"%s*:%s*(%d+)')
  local insert_sp = lang_block and lang_block:match('"editor%.insertSpaces"%s*:%s*(%a+)')

  -- Fall back to global settings
  tab_size  = tab_size  or content:match('"editor%.tabSize"%s*:%s*(%d+)')
  insert_sp = insert_sp or content:match('"editor%.insertSpaces"%s*:%s*(%a+)')

  if tab_size or insert_sp then
    local size = tonumber(tab_size) or 4
    return { tabstop = size, shiftwidth = size, expandtab = insert_sp ~= 'false' }
  end
end

-- ── Apply & resolve ───────────────────────────────────────────────────────

-- Apply resolved settings.  When `size_only` is true, only tabstop/shiftwidth
-- are written — expandtab is left untouched (EditorConfig's indent_style wins).
local function apply(bufnr, s, size_only)
  vim.bo[bufnr].tabstop     = s.tabstop
  vim.bo[bufnr].shiftwidth  = s.shiftwidth
  vim.bo[bufnr].softtabstop = s.tabstop
  if not size_only then
    vim.bo[bufnr].expandtab = s.expandtab
  end
end

function M.resolve(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then return end

  local bufdir = vim.fn.fnamemodify(path, ':h')
  local ft     = vim.bo[bufnr].filetype
  if ft == '' then return end

  -- Priority 1: .editorconfig
  -- If EditorConfig set a concrete indent *size* (numeric indent_size or tab_width),
  -- it fully owns indentation — nothing more to do.
  -- If it only set indent_style (tabs vs spaces) without a concrete size, we still
  -- need to determine the width from the rest of the chain, but we must NOT override
  -- the expandtab value that EditorConfig already set.
  -- NOTE: indent_size = "tab" without tab_width is NOT a concrete size.
  local ec_has_size, ec_has_style = editorconfig_indent_coverage(bufnr)
  if ec_has_size then return end

  local size_only = ec_has_style -- preserve EditorConfig's expandtab when it set indent_style

  local root = project_root(bufdir)
  local key  = root .. ':' .. ft

  if _cache[key] ~= nil then
    -- false means "no IDE config at this root for this ft"; fall through to lang defaults
    if _cache[key] then
      apply(bufnr, _cache[key], size_only)
      return
    end
  else
    -- Priorities 2 → 4: first IDE config file that matches wins
    local settings = parse_intellij(root, ft)
                  or parse_eclipse(root, ft)
                  or parse_vscode(root, ft)
    _cache[key] = settings or false
    if settings then
      apply(bufnr, settings, size_only)
      return
    end
  end

  -- Priority 5: language-specific defaults
  local def = _lang_defaults[ft]
  if def then apply(bufnr, def, size_only) end

  -- Priority 6: guess-indent.nvim already ran on BufReadPost; we do not call it here.
  -- For filetypes with no entry in _lang_defaults its inference stands.
end

function M.setup()
  local group = vim.api.nvim_create_augroup('indent-chain', { clear = true })

  -- Use BufReadPost (not FileType) so we run in the same event as EditorConfig and
  -- guess-indent.  vim.schedule defers the callback until after ALL BufReadPost
  -- handlers have finished, guaranteeing that:
  --   - vim.bo.filetype is set (filetype detection fires first in BufReadPost)
  --   - vim.b.editorconfig is populated (built-in EditorConfig handler has run)
  --   - guess-indent.nvim has already applied its inference
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    group = group,
    callback = function(ev)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) and vim.bo[ev.buf].filetype ~= '' then
          M.resolve(ev.buf)
        end
      end)
    end,
  })

  -- Also handle filetype changes after initial load (e.g. :setfiletype java)
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function(ev)
      -- Only for buffers that have already been loaded (have a name)
      if vim.api.nvim_buf_get_name(ev.buf) ~= '' then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then
            M.resolve(ev.buf)
          end
        end)
      end
    end,
  })
end

return M
