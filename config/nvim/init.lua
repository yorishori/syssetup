-- Step 1: plain nvim, no plugins. Only options and a few keymaps.
-- Help for any option: :help 'optionname'   (e.g. :help 'scrolloff')

vim.g.mapleader = " "

-- Look
vim.opt.number = true           -- line numbers
vim.opt.cursorline = true       -- highlight the current line
vim.opt.colorcolumn = "128"     -- ruler at column 128
vim.opt.scrolloff = 8           -- keep 8 lines visible above/below the cursor
vim.opt.signcolumn = "yes"      -- fixed gutter, so text doesn't jump sideways later

-- Mouse and clipboard
vim.opt.mouse = "a"             -- mouse everywhere (click, drag-select, scroll)
vim.opt.clipboard = "unnamedplus" -- y/p use the system clipboard

-- Indentation: 3 spaces
vim.opt.tabstop = 3
vim.opt.shiftwidth = 3
vim.opt.softtabstop = 3
vim.opt.expandtab = true

-- Search: case-insensitive unless the search has a capital letter
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Splits open to the right / below
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Undo survives closing the file
vim.opt.undofile = true

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<leader>w", "<cmd>setlocal wrap!<CR>", { desc = "Toggle line wrap" })

-- Briefly highlight what was yanked
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.hl.on_yank() end,
})

-- Reopen files where the cursor was left
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function(event)
        local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
