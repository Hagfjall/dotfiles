vim.api.nvim_set_keymap("n", "'", "<ts>", {})

require("nvim-treesitter.configs").setup({
	ensure_installed = "all", -- one of 'all', 'language', or a list of languages
	highlight = {
		enable = true, -- false will disable the whole extension
		disable = {}, -- list of language that will be disabled
		additional_vim_regex_highlighting = false,
	},
	incremental_selection = {
		enable = true,
		keymaps = { -- mappings for incremental selection (visual mappings)
			-- node_incremental = "grn", -- increment to the upper named parent
			-- scope_incremental = "grc", -- increment to the upper scope (as defined in locals.scm)
			-- init_selection = 'gnn', -- maps in normal mode to init the node/scope selection
			-- node_decremental = "grm" -- decrement to the previous node
			init_selection = "<CR>",
			scope_incremental = "<CR>",
			node_incremental = "<TAB>",
			node_decremental = "<S-TAB>",
		},
	},
	indent = { enable = false, disable = { "python" } },
	refactor = {
		highlight_definitions = { enable = false },
		highlight_current_scope = { enable = false },
		smart_rename = {
			enable = true,
			keymaps = {
				smart_rename = "'r", -- mapping to rename reference under cursor
			},
		},
		navigation = {
			enable = true,
			keymaps = {
				goto_definition = "'d", -- mapping to go to definition of symbol under cursor
				list_definitions = "'D", -- mapping to list all definitions in current file
			},
		},
	},
	textobjects = { -- syntax-aware textobjects
		select = {
			enable = true,
			disable = {},
			keymaps = {
				["aF"] = "@function.outer",
				["iF"] = "@function.inner",
				["aC"] = "@class.outer",
				["iC"] = "@class.inner",
				["iB"] = "@block.inner",
				["aB"] = "@block.outer",
				-- use sandwich
				-- ["i"] = "@call.inner",
				-- ["a"] = "@call.outer",
				-- ["a"] = "@comment.outer",
				["iI"] = "@conditional.inner",
				["aI"] = "@conditional.outer",
				["iL"] = "@loop.inner",
				["aL"] = "@loop.outer",
				["iP"] = "@parameter.inner",
				["aP"] = "@parameter.outer",
				["aS"] = "@statement.outer",
			},
		},
		swap = {
			enable = true,
			swap_next = { ["'>>"] = "@parameter.inner" },
			swap_previous = { ["'<<"] = "@parameter.inner" },
		},
		move = {
			enable = true,
			goto_next_start = { ["]m"] = "@function.outer", ["]]"] = "@class.outer" },
			goto_next_end = { ["]M"] = "@function.outer", ["]["] = "@class.outer" },
			goto_previous_start = { ["[m"] = "@function.outer", ["[["] = "@class.outer" },
			goto_previous_end = { ["[M"] = "@function.outer", ["[]"] = "@class.outer" },
		},
	},
	textsubjects = {
		enable = true,
		-- prev_selection = ",", -- (Optional) keymap to select the previous selection
		keymaps = {
			["."] = "textsubjects-smart",
			["'"] = "textsubjects-container-outer",
			['"'] = "textsubjects-container-inner",
		},
	},
	rainbow = {
		enable = true,
		extended_mode = true,
		max_file_lines = 300,
		disable = { "cpp" }, -- please disable lua and bash for now
	},
	pairs = {
		enable = false,
		disable = {},
		highlight_pair_events = { "CursorMoved" }, -- when to highlight the pairs, use {} to deactivate highlighting
		highlight_self = true,
		goto_right_end = false, -- whether to go to the end of the right partner or the beginning
		fallback_cmd_normal = "call matchit#Match_wrapper('',1,'n')", -- What command to issue when we can't find a pair (e.g. "normal! %")
		keymaps = { goto_partner = "'%" },
	},
	context_commentstring = { enable = true },
	yati = { enable = true },
})

vim.api.nvim_set_keymap("n", "<SubLeader>e", "<Cmd>e!<CR>", { noremap = false, silent = true })
