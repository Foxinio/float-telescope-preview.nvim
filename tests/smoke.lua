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
	return { select_default = { replace = function(_, callback) select = callback end } }
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

package.preload.telescope = function()
	return { register_extension = function(spec) return spec end }
end

local extension = dofile('lua/telescope/_extensions/float_command.lua')
assert(extension.exports.open == command.open)
