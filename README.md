# MCOS (**M**ulti**c**cursor **O**n **S**elect)

This is an extension of
[jake-stewart/multicursor.nvim](https://github.com/jake-stewart/multicursor.nvim)
that creates a user command for adding multicursors on a selection with preview
as you type!

## Install

Use lazy plugin manager

```lua
{
	"zaucy/mcos.nvim",
	dependencies = {
		"jake-stewart/multicursor.nvim",
	},
	config = function()
		local mcos = require('mcos')
		mcos.setup({})

		-- mcos doesn't setup any keymaps
		-- here are some recommended ones
		vim.keymap.set({ 'n', "v" }, 'gms', mcos.opkeymapfunc, { expr = true })
		vim.keymap.set({ 'n' }, 'gmss', mcos.bufkeymapfunc)
	end,
}
```
