package.path = './lua/?.lua;./lua/?/init.lua;' .. package.path

local command = require('float-command')
for _, name in ipairs({ 'open', 'open_file', 'open_lsp', 'open_telescope', 'open_telescope_selection' }) do
	assert(type(command[name]) == 'function', name .. ' is not exported')
end

package.preload.telescope = function()
	return { register_extension = function(spec) return spec end }
end

local extension = dofile('lua/telescope/_extensions/float_command.lua')
assert(extension.exports.open == command.open)
