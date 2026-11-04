local M = {}
function M.palette()
  local dark = vim.o.background == 'dark'
  local function color(group, attr, fallback)
    local value = vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
    return value and string.format('#%06x', value) or fallback
  end
  local bg = color('Normal', 'bg', dark and '#1f2335' or '#ffffff')
  local fg = color('Normal', 'fg', dark and '#c0caf5' or '#24283b')
  local palette = {
    ['--pele-bg'] = bg,
    ['--pele-fg'] = fg,
    ['--pele-muted'] = color('Comment', 'fg', fg),
    ['--pele-line'] = fg,
    ['--pele-surface'] = color('NormalFloat', 'bg', bg),
    ['--pele-surface-alt'] = color('CursorLine', 'bg', bg),
    ['--pele-border'] = color('FloatBorder', 'fg', fg),
    ['--pele-accent'] = color('Function', 'fg', fg),
  }
  for i, group in ipairs({ 'Function', 'String', 'Keyword', 'Number', 'Type', 'Special', 'DiagnosticInfo', 'DiagnosticWarn' }) do
    palette['--pele-series-' .. i] = color(group, 'fg', fg)
  end
  return palette
end
return M
