local M = {}

M.setcmdline_delayed = vim.schedule_wrap(function(cmdline, pos)
	vim.fn.setcmdline(cmdline, pos)
	M.refresh_cmdline()
end)

function M.refresh_cmdline()
	local backspace = vim.api.nvim_replace_termcodes("<bs>", true, false, true)
	-- Hack to trigger command preview again after new buffer contents have been computed
	vim.api.nvim_feedkeys("a" .. backspace, "n", false)
end

return M
