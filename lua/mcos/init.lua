local util = require('mcos.util')

local M = {}

local function mcos_command(ns, opts, cmd_opts)
	local line1 = cmd_opts.line1
	local line2 = cmd_opts.line2
	local buf = vim.api.nvim_get_current_buf()
	local pat = cmd_opts.args
	local cursors = {}
	local cursor_hl = vim.api.nvim_get_hl_id_by_name("MultiCursorCursor")
	local search_hl = vim.api.nvim_get_hl_id_by_name("MultiCursorMatchPreview")
	local visual_hl = vim.api.nvim_get_hl_id_by_name("MultiCursorVisual")

	if #pat > 0 then
		while line1 ~= line2 + 1 do
			local line_iteration_count = 0
			local last_idx = 0
			while line_iteration_count < opts.max_line_matches do
				local line = vim.api.nvim_buf_get_lines(buf, line1 - 1, line1, false)[1]
				local start_idx, end_idx = string.find(line, pat, last_idx + 1, true)
				if not start_idx or not end_idx then break end
				vim.api.nvim_buf_set_extmark(buf, ns, line1 - 1, start_idx, {
					hl_group = search_hl,
					end_row = line1 - 1,
					end_col = end_idx,
					priority = 48,
				})

				local cursor_id = vim.api.nvim_buf_set_extmark(buf, ns, line1 - 1, start_idx - 1, {
					hl_group = cursor_hl,
					end_row = line1 - 1,
					end_col = start_idx,
					priority = 20000,
				})

				table.insert(cursors, cursor_id)
				last_idx = end_idx + 1
				line_iteration_count = line_iteration_count + 1
			end

			line1 = line1 + 1
		end
	else
		vim.api.nvim_buf_set_extmark(buf, ns, line1 - 1, 0, {
			hl_group = visual_hl,
			hl_eol = true,
			end_row = line2,
			end_col = 0,
		})
	end

	for _, cursor_id in ipairs(cursors) do
		local cursor = vim.api.nvim_buf_get_extmark_by_id(buf, ns, cursor_id, {})
		vim.api.nvim_buf_set_extmark(buf, ns, cursor[1], cursor[2], {
			hl_group = cursor_hl,
			end_row = cursor[1],
			end_col = cursor[2] + 1,
			priority = 49,
		})
	end

	return cursors
end

function M.setup(opts)
	opts = vim.tbl_extend('keep', opts, {
		max_line_matches = 256,
	})
	vim.api.nvim_create_user_command("MCOS", function(cmd_opts)
		local mc = require("multicursor-nvim")
		local ns = vim.api.nvim_create_namespace("MCOS")
		local success, error_or_cursors = pcall(mcos_command, ns, opts, cmd_opts)
		if success then
			local cursor_positions = {}
			for _, cursor_id in ipairs(error_or_cursors) do
				local cursor_pos = vim.api.nvim_buf_get_extmark_by_id(0, ns, cursor_id, {})
				table.insert(cursor_positions, { cursor_pos[1] + 1, cursor_pos[2] + 1 })
			end
			vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
			mc.action(function(ctx)
				ctx:clear()
				--- @type Cursor[]
				local cursors = {}
				for _, cursor_pos in ipairs(cursor_positions) do
					local cursor = ctx:addCursor()
					cursor:setPos(cursor_pos)
					table.insert(cursors, cursor)
				end

				if #cursors > 0 then
					ctx:mainCursor():delete()
					cursors[1]:select()
				end
			end)
		else
			vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
			error(error_or_cursors, vim.log.levels.ERROR)
		end
	end, {
		nargs = "*",
		range = true,
		preview = function(cmd_opts, preview_ns, preview_buf)
			local success, error_or_cursors = pcall(mcos_command, preview_ns, opts, cmd_opts)
			if not success then
				---@type string
				---@diagnostic disable-next-line: assign-type-mismatch
				local error_message = error_or_cursors
				local buf = vim.api.nvim_get_current_buf()
				vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Preview Function Failed", error_message })
				return 2
			end
			return 2
		end,
	})

	function _G.McosOperatorFunc(motion_type)
		return M._operatorfunc(motion_type)
	end
end

local function mcos_cmdline(range)
	vim.fn.feedkeys(":")
	local cmdline = range .. "MCOS "
	util.setcmdline_delayed(cmdline, #cmdline + 1)
end

function M._operatorfunc(_)
	vim.cmd("normal! `[v`]")
	mcos_cmdline("'<,'>")
end

function M.opkeymapfunc()
	vim.opt.operatorfunc = 'v:lua.McosOperatorFunc'
	return 'g@'
end

function M.bufkeymapfunc()
	mcos_cmdline("%")
end

return M
