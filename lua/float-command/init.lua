local M = {}

local config = {
	border = 'rounded',
	width = 0.8,
	height = 0.8,
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

-- A placeholder buffer that disappears once a command replaces it (e.g. :edit).
local function scratch()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = 'wipe'
	return buf
end

local function open_float(buf)
	local win = vim.api.nvim_open_win(buf, true, dimensions())
	for option, value in pairs(config.win_opts) do
		vim.api.nvim_set_option_value(option, value, { scope = 'local', win = win })
	end
	local group = vim.api.nvim_create_augroup('float-command-' .. win, { clear = true })
	vim.api.nvim_create_autocmd('WinLeave', {
		group = group,
		nested = true,
		callback = function()
			-- Close only when leaving the float itself, not on unrelated window changes.
			if vim.api.nvim_get_current_win() == win then
				vim.schedule(function() pcall(vim.api.nvim_win_close, win, true) end)
			end
		end,
	})
	vim.api.nvim_create_autocmd('VimResized', {
		group = group,
		callback = function() pcall(vim.api.nvim_win_set_config, win, dimensions()) end,
	})
	vim.api.nvim_create_autocmd('WinClosed', {
		group = group,
		pattern = tostring(win),
		callback = function() pcall(vim.api.nvim_del_augroup_by_id, group) end,
	})
	return win
end

function M.setup(opts)
	config = vim.tbl_deep_extend('force', config, opts or {})
end

function M.open(command)
	local original_win = vim.api.nvim_get_current_win()
	local win = open_float(scratch())

	local ok, err
	if type(command) == 'function' then
		ok, err = pcall(command)
	else
		ok, err = pcall(vim.cmd, command)
	end
	if not ok then
		pcall(vim.api.nvim_win_close, win, true)
		if vim.api.nvim_win_is_valid(original_win) then
			vim.api.nvim_set_current_win(original_win)
		end
		vim.notify(err, vim.log.levels.ERROR)
	end
	return win
end

function M.open_file(path)
	if type(path) == 'string' and path ~= '' then
		M.open(function() vim.cmd.edit(vim.fn.fnameescape(path)) end)
	end
end

-- `action` is an LSP location request such as vim.lsp.buf.definition. A single
-- location opens in the float, several go to the quickfix list, none notifies.
function M.open_lsp(action)
	action({
		on_list = function(list)
			local items = list.items or {}
			if #items == 0 then
				vim.notify('No locations found', vim.log.levels.INFO)
			elseif #items > 1 then
				vim.fn.setqflist({}, ' ', list)
				vim.cmd('botright copen')
			else
				local item = items[1]
				M.open(function()
					if item.bufnr and vim.api.nvim_buf_is_valid(item.bufnr) then
						vim.bo[item.bufnr].buflisted = true
						vim.api.nvim_win_set_buf(0, item.bufnr)
					else
						vim.cmd.edit(vim.fn.fnameescape(item.filename))
					end
					pcall(vim.api.nvim_win_set_cursor, 0, { item.lnum, math.max((item.col or 1) - 1, 0) })
				end)
			end
		end,
	})
end

function M.open_telescope_selection(prompt_bufnr)
	local entry = require('telescope.actions.state').get_selected_entry()
	if not entry then
		return
	end

	require('telescope.actions').close(prompt_bufnr)

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

		open_float(scratch())
		vim.cmd.edit(vim.fn.fnameescape(path))
	end

	local row = entry.row or entry.lnum
	if row then
		pcall(vim.api.nvim_win_set_cursor, 0, { row, math.max((entry.col or 1) - 1, 0) })
	end
end

function M.open_telescope(picker, opts)
	opts = opts or {}
	local attach_mappings = opts.attach_mappings
	picker(vim.tbl_extend('force', { jump_type = 'never' }, opts, {
		attach_mappings = function(prompt_bufnr, map)
			require('telescope.actions').select_default:replace(function()
				M.open_telescope_selection(prompt_bufnr)
			end)
			return not attach_mappings or attach_mappings(prompt_bufnr, map)
		end,
	}))
end

return M
