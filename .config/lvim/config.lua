-- ══════════════════════════════════════════════════════════════════════════════
-- VIM OPTIONS
-- ══════════════════════════════════════════════════════════════════════════════
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.relativenumber = true
vim.opt.scrolloff = 8     -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor
vim.opt.wrap = false      -- Don't wrap lines
vim.opt.cursorline = true -- Highlight current line

-- ══════════════════════════════════════════════════════════════════════════════
-- GENERAL
-- ══════════════════════════════════════════════════════════════════════════════
lvim.log.level = "warn" -- Less noisy than "info"
lvim.format_on_save = {
  enabled = true,
  pattern = { "*.lua", "*.py" }, -- Add Python
  timeout = 1000,
}
vim.g.deprecation_warnings = false

-- ══════════════════════════════════════════════════════════════════════════════
-- KEYMAPPINGS
-- ══════════════════════════════════════════════════════════════════════════════
lvim.leader = "space"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"

-- Buffer navigation (uncomment these - very useful)
lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"
lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"

-- Close buffer without closing window
lvim.keys.normal_mode["<leader>x"] = ":BufferKill<CR>"

-- Remove the dead SnipRun keybinding (or uncomment the plugin)
-- lvim.keys.normal_mode["<leader>r"] = ":%SnipRun<CR>"

-- ══════════════════════════════════════════════════════════════════════════════
-- PYTHON SETUP (since you're a Python dev)
-- ══════════════════════════════════════════════════════════════════════════════
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  { command = "ruff", filetypes = { "python" } }, -- Fast Python formatter
}

local linters = require "lvim.lsp.null-ls.linters"
linters.setup {
  { command = "ruff", filetypes = { "python" } }, -- Fast Python linter
}

-- ══════════════════════════════════════════════════════════════════════════════
-- PLUGINS
-- ══════════════════════════════════════════════════════════════════════════════
lvim.plugins = {
  -- Catppuccin theme (matches your terminal)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
  },
}

-- Set colorscheme to match WezTerm
lvim.colorscheme = "catppuccin-macchiato"

-- ══════════════════════════════════════════════════════════════════════════════
-- AUTOCOMMANDS
-- ══════════════════════════════════════════════════════════════════════════════

-- Restore cursor position when reopening file
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "Visual", timeout = 150 })
  end,
})
