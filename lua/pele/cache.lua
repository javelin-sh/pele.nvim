local M = {}
local entries = {}
local function key(source, palette, node)
  local colors = {}
  for _, name in ipairs(vim.tbl_keys(palette)) do
    colors[#colors + 1] = name .. '=' .. palette[name]
  end
  table.sort(colors)
  return vim.fn.sha256(vim.json.encode({ source, colors, node }))
end
function M.get(source, palette, node, renderer, callback)
  local id = key(source, palette, node)
  local entry = entries[id]
  if entry then
    if entry.ready then callback(entry.path, nil)
    else table.insert(entry.callbacks, callback) end
    return
  end
  entry = { path = vim.fn.tempname() .. '.png', callbacks = { callback } }
  entries[id] = entry
  entry.job = vim.system({ node, renderer, entry.path, vim.json.encode(palette) },
    { stdin = source, text = true, timeout = 15000 }, vim.schedule_wrap(function(result)
      if entries[id] ~= entry then vim.fn.delete(entry.path); return end
      local err = result.code ~= 0 and (result.stderr or 'render failed') or nil
      entry.job = nil
      entry.ready = not err
      if err then entries[id] = nil; vim.fn.delete(entry.path) end
      local callbacks = entry.callbacks
      entry.callbacks = nil
      for _, notify in ipairs(callbacks) do notify(entry.path, err) end
    end))
end
function M.clear()
  local old = entries
  entries = {}
  for _, entry in pairs(old) do
    if entry.job then entry.job:kill(15) end
    vim.fn.delete(entry.path)
  end
end
return M
