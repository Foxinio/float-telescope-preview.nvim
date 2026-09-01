package.path = './lua/?.lua;./lua/?/init.lua;' .. package.path

local command = require('float-command')
for _, name in ipairs({ 'setup', 'open', 'open_file', 'open_lsp', 'open_telescope', 'open_telescope_selection' }) do
	assert(type(command[name]) == 'function', name .. ' is not exported')
end

command.setup({ padding = 1, win_opts = { number = false } })
command.open('enew')
local win = vim.api.nvim_get_current_win()
local float = vim.api.nvim_win_get_config(win)
assert(float.relative == 'editor')
assert(float.width == vim.o.columns - 4)
assert(vim.api.nvim_get_option_value('number', { win = win }) == false)
vim.api.nvim_win_close(win, true)

package.preload.telescope = function()
	return { register_extension = function(spec) return spec end }
end

local extension = dofile('lua/telescope/_extensions/float_command.lua')
assert(extension.exports.open == command.open)
