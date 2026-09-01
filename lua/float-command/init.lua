local M = {}

local config = {
	border = 'rounded',
	width = 0.8,
	height = 0.8,
	zindex = nil,
	win_opts = {},
}

local function dimensions()
	local width = math.floor(vim.o.columns * config.width)
	local height = math.floor(vim.o.lines * config.height)
	return {
		relative = 'editor',
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		width = width,
		height = height,
		border = config.border,
		zindex = config.zindex,
		style = 'minimal',
	}
end

local function open_float(buf)
	local win = vim.api.nvim_open_win(buf, true, dimensions())
	for option, value in pairs(config.win_opts) do
		vim.api.nvim_set_option_value(option, value, { scope = 'local', win = win })
	end
	vim.api.nvim_create_autocmd('WinLeave', {
		once = true,
		nested = true,
		callback = function() pcall(vim.api.nvim_win_close, win, true) end,
	})
	vim.api.nvim_create_autocmd('VimResized', {
		callback = function()
			local exists = pcall(vim.api.nvim_win_set_config, win, dimensions())
			return not exists
		end,
	})
	return win
end

function M.setup(opts)
	config = vim.tbl_deep_extend('force', config, opts or {})
end

function M.open(command)
	local buf = vim.api.nvim_create_buf(false, true)
	local original_win = vim.api.nvim_get_current_win()
	open_float(buf)

	local ok, err
	if type(command) == 'function' then
		ok, err = pcall(command)
	else
		ok, err = pcall(vim.cmd, command)
	end
	if not ok then
		if vim.api.nvim_win_is_valid(original_win) then
			vim.api.nvim_set_current_win(original_win)
		end
		vim.notify(err, vim.log.levels.ERROR)
	end
end

function M.open_file(path)
	if type(path) == 'string' and path ~= '' then
		M.open(function() vim.cmd.edit(vim.fn.fnameescape(path)) end)
	end
end

function M.open_lsp(action)
	M.open(action)
end

function M.open_telescope_selection(prompt_bufnr)
	local entry = require('telescope.actions.state').get_selected_entry()
	if not entry then
		return
	end

	require('telescope.pickers').on_close_prompt(prompt_bufnr)

	local bufnr = entry.bufnr
	if bufnr then
		if not vim.bo[bufnr].buflisted then
			vim.bo[bufnr].buflisted = true
		end
		open_float(bufnr)
	else
		local path = entry.path or entry.filename or entry.value
		if type(path) ~= 'string' or path == '' then
			return
		end

		open_float(vim.api.nvim_create_buf(false, true))
		vim.cmd.edit(vim.fn.fnameescape(path))
	end

	local row = entry.row or entry.lnum
	if row then
		pcall(vim.api.nvim_win_set_cursor, 0, { row, math.max((entry.col or 1) - 1, 0) })
	end
end

function M.open_telescope(picker)
	picker({
		jump_type = 'never',
		attach_mappings = function(prompt_bufnr)
			require('telescope.actions').select_default:replace(function()
				M.open_telescope_selection(prompt_bufnr)
			end)
			return true
		end,
	})
end

return M
