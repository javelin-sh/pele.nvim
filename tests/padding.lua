vim.opt.rtp:prepend(vim.fn.getcwd())
vim.o.conceallevel = 2
vim.o.concealcursor = 'n'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {'```mermaid','A-->B','```','following text'})
local ns = vim.api.nvim_create_namespace('pele-padding-check')
vim.api.nvim_buf_set_extmark(0, ns, 2, 0, {end_row=3, conceal_lines=''})
local row = require('pele.blocks').parse(vim.api.nvim_buf_get_lines(0,0,-1,false))[1].row
vim.api.nvim_buf_set_extmark(0, ns, row, 0, {virt_lines={{{' ',''}},{{' ',''}},{{' ',''}}}})
vim.cmd('redraw')
local anchor = vim.fn.screenpos(0, row+1, 1).row
local following = vim.fn.screenpos(0, 4, 1).row
assert(following - anchor >= 4, vim.inspect({anchor=anchor, following=following}))
print('Concealed fence preserves preview padding')
vim.cmd('qa!')
