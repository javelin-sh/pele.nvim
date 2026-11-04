local M = {}
local cache = require('pele.cache')
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
local states, serial = {}, 0
local opts = { node = 'node', debounce = 300, width = 80, height = 24, filetypes = { 'markdown' } }
local enabled = true
local inserting = false
local function clear(win)
  local state = states[win]
  if not state then return end
  states[win] = nil
  for _, img in ipairs(state.images) do img:clear() end
end
function M.clear()
  for win in pairs(states) do clear(win) end
end
function M.render(force)
  if not enabled or inserting then return end
  local palette = require('pele.theme').palette()
  for win in pairs(states) do
    if not vim.api.nvim_win_is_valid(win) then clear(win) end
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local tick = vim.api.nvim_buf_get_changedtick(buf)
    local width = vim.api.nvim_win_get_width(win)
    local height = vim.api.nvim_win_get_height(win)
    local previous = states[win]
    if not force and previous and previous.buf == buf and previous.tick == tick
      and previous.width == width and previous.height == height and vim.deep_equal(previous.palette, palette) then
      -- image.nvim tracks scrolling; unchanged previews need no rebuild.
    else
      clear(win)
      if vim.tbl_contains(opts.filetypes, vim.bo[buf].filetype) then
        local blocks = require('pele.blocks').parse(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
        if #blocks > 0 then
          local ok, api = pcall(require, 'image')
          if not ok then vim.notify('pele.nvim requires image.nvim', vim.log.levels.ERROR); return end
          local state = { images = {}, buf = buf, tick = tick, width = width, height = height, palette = palette }
          states[win] = state
          local tick = vim.api.nvim_buf_get_changedtick(buf)
          for _, block in ipairs(blocks) do
            cache.get(block.source, palette, opts.node, root .. '/scripts/render.mjs', function(path, err)
              if inserting or states[win] ~= state or not vim.api.nvim_win_is_valid(win) or not vim.api.nvim_buf_is_valid(buf)
                or vim.api.nvim_win_get_buf(win) ~= buf or vim.api.nvim_buf_get_changedtick(buf) ~= tick then
                return
              end
              if err then
                vim.notify('Pele: ' .. err, vim.log.levels.WARN); return
              end
              local success, img = pcall(api.from_file, path, {
                id = 'pele-' .. win .. '-' .. block.row, window = win, buffer = buf,
                inline = true, with_virtual_padding = true, render_offset_top = 1, x = 0, y = block.row,
                width = math.min(opts.width, vim.api.nvim_win_get_width(win)), height = opts.height,
              })
              if success and img then table.insert(state.images, img); img:render()
              else vim.notify('Pele image: ' .. tostring(img), vim.log.levels.ERROR) end
            end)
          end
        end
      end
    end
  end
end
function M.setup(config)
  M.clear()
  opts = vim.tbl_deep_extend('force', opts, config or {})
  local group = vim.api.nvim_create_augroup('Pele', { clear = true })
  local function schedule()
    serial = serial + 1
    local request = serial
    vim.defer_fn(function() if request == serial then M.render() end end, opts.debounce)
  end
  vim.api.nvim_create_autocmd('InsertEnter', { group = group, callback = function()
    inserting = true
    serial = serial + 1
    M.clear()
  end })
  vim.api.nvim_create_autocmd('InsertLeave', { group = group, callback = function()
    inserting = false
    schedule()
  end })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'WinClosed', 'VimResized', 'FileType' }, { group = group, callback = schedule })
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufWinLeave' }, { group = group, callback = function()
    serial = serial + 1
    local request = serial
    vim.schedule(function() if request == serial then M.render() end end)
  end })
  vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = schedule })
  vim.api.nvim_create_autocmd('OptionSet', { group = group, pattern = 'background', callback = schedule })
  vim.api.nvim_create_autocmd('VimLeavePre', { group = group, callback = function() M.clear(); cache.clear() end })
  vim.api.nvim_create_user_command('PeleRender', function() M.render(true) end, { force = true })
  vim.api.nvim_create_user_command('PeleToggle', function() enabled = not enabled; M.clear(); if enabled then M.render() end end, { force = true })
  schedule()
end
return M
