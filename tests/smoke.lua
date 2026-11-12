package.path = './lua/?.lua;./lua/?/init.lua;' .. package.path

local command = require('float-command')
for _, name in ipairs({ 'setup', 'open', 'open_file', 'open_lsp', 'open_telescope', 'open_telescope_selection' }) do
	assert(type(command[name]) == 'function', name .. ' is not exported')
end

command.setup({ win_opts = { wrap = false } })
command.open('enew')
local win = vim.api.nvim_get_current_win()
local float = vim.api.nvim_win_get_config(win)
assert(float.relative == 'editor')
assert(float.width == math.floor(vim.o.columns * 0.8))
assert(float.height == math.floor(vim.o.lines * 0.8))
assert(float.border[1] == '╭')
assert(vim.api.nvim_get_option_value('wrap', { win = win }) == false)
vim.api.nvim_win_close(win, true)

local selection = vim.api.nvim_create_buf(true, false)
local select
package.preload['telescope.actions.state'] = function()
	return { get_selected_entry = function() return { bufnr = selection } end }
end
package.preload['telescope.pickers'] = function()
	return { on_close_prompt = function() end }
end
package.preload['telescope.actions'] = function()
	return { close = function() end, select_default = { replace = function(_, callback) select = callback end } }
end

vim.wo.number = true
command.open_telescope(function(opts)
	vim.cmd.new()
	vim.wo.number = false
	opts.attach_mappings(0)
	select()
end)
win = vim.api.nvim_get_current_win()
assert(vim.api.nvim_get_option_value('number', { win = win }) == false)
vim.api.nvim_win_close(win, true)

-- Leaving the float closes it and removes its autocmds.
win = command.open('enew')
local group = 'float-command-' .. win
assert(#vim.api.nvim_get_autocmds({ group = group }) > 0)
vim.cmd.wincmd('p')
vim.wait(50, function() return not vim.api.nvim_win_is_valid(win) end)
assert(not vim.api.nvim_win_is_valid(win), 'float closes when left')
assert(not pcall(vim.api.nvim_get_autocmds, { group = group }), 'float autocmds removed')

-- A failing command closes the float again.
local notify = vim.notify
vim.notify = function() end
local before = #vim.api.nvim_list_wins()
command.open('this-is-not-a-command')
vim.notify = notify
assert(#vim.api.nvim_list_wins() == before, 'failed command leaves no float')

-- open_lsp: one location opens a float, none opens nothing.
local file = vim.fn.tempname()
vim.fn.writefile({ 'a', 'b', 'c' }, file)
command.open_lsp(function(opts) opts.on_list({ items = { { filename = file, lnum = 2, col = 1 } } }) end)
assert(vim.api.nvim_win_get_config(0).relative == 'editor' and vim.api.nvim_win_get_cursor(0)[1] == 2)
vim.api.nvim_win_close(0, true)
before = #vim.api.nvim_list_wins()
vim.notify = function() end
command.open_lsp(function(opts) opts.on_list({ items = {} }) end)
vim.notify = notify
assert(#vim.api.nvim_list_wins() == before)

package.preload.telescope = function()
	return { register_extension = function(spec) return spec end }
end

local extension = dofile('lua/telescope/_extensions/float_command.lua')
assert(extension.exports.open == command.open)
