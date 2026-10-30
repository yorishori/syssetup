-- Options and keymaps. Plugins live in plugin/, one file each, and are loaded automatically after this file.
-- Help for any option: :help 'optionname'   (e.g. :help 'scrolloff')

vim.g.mapleader = " "

-- Look
vim.opt.number = true           -- line numbers
vim.opt.cursorline = true       -- highlight the current line
vim.opt.colorcolumn = "128"     -- ruler at column 128
vim.opt.scrolloff = 8           -- keep 8 lines visible above/below the cursor
vim.opt.signcolumn = "yes"      -- fixed gutter, so text doesn't jump sideways later
vim.opt.list = true             -- show tab characters as » (spaces stay invisible)
vim.opt.listchars = { tab = "» ", nbsp = "␣" }

-- Mouse and clipboard
vim.opt.mouse = "a"             -- mouse everywhere (click, drag-select, scroll)
vim.opt.clipboard = "unnamedplus" -- y/d/p use the system clipboard

-- d is cut (system clipboard); x, s and c only delete, so they never clobber the clipboard.
-- "_ is the black hole register: whatever goes in is discarded.
for _, key in ipairs({ "x", "X", "s", "S", "c", "C" }) do
    vim.keymap.set({ "n", "x" }, key, '"_' .. key, { desc = "Delete without copying" })
end
-- Pasting over a selection keeps the clipboard instead of replacing it with the selection
vim.keymap.set("x", "p", "P", { desc = "Paste over selection, keep clipboard" })

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

-- Tab bar: tabs are named after their file (sidebars like the file tree are skipped), ● when unsaved,
-- click a tab to switch to it, ✕ to close it
function _G.tabline()
    local line = ""
    for tab = 1, vim.fn.tabpagenr("$") do
        local buffers = vim.fn.tabpagebuflist(tab)
        local buf = buffers[vim.fn.tabpagewinnr(tab)]
        if vim.bo[buf].buftype ~= "" then
            for _, b in ipairs(buffers) do
                if vim.bo[b].buftype == "" then buf = b break end
            end
        end
        local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
        if name == "" then name = "[No Name]" end
        if vim.bo[buf].modified then name = name .. " ●" end
        local hl = tab == vim.fn.tabpagenr() and "%#TabLineSel#" or "%#TabLine#"
        line = line .. hl .. "%" .. tab .. "T " .. name .. " %" .. tab .. "X✕%X "
    end
    return line .. "%#TabLineFill#%T"
end
vim.opt.tabline = "%!v:lua.tabline()"

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<leader>w", "<cmd>setlocal wrap!<CR>", { desc = "Toggle line wrap" })
vim.keymap.set("n", "<C-n>", "<cmd>tabnew<CR>", { desc = "New file in a new tab" })
-- Ctrl+P, Ctrl+F: see plugin/search.lua. Ctrl+B: see plugin/tree.lua.

vim.keymap.set("n", "<A-j>", "<cmd>move .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-k>", "<cmd>move .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("x", "<A-j>", ":move '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
vim.keymap.set("x", "<A-k>", ":move '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })

-- Indenting a selection keeps it selected, so > or < can be pressed again
vim.keymap.set("x", ">", ">gv", { desc = "Indent, keep selection" })
vim.keymap.set("x", "<", "<gv", { desc = "Unindent, keep selection" })

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
