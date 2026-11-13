if vim.g.loaded_float_command then return end
vim.g.loaded_float_command = true

vim.api.nvim_create_user_command('Float', function(opts)
	require('float-command').open(opts.args)
end, { nargs = '+', complete = 'command', desc = 'Run an Ex command in a floating window', force = true })
