vim.opt.number = true

vim.opt.clipboard = "unnamedplus"

vim.opt.tabstop = 3
vim.opt.shiftwidth = 3
vim.opt.softtabstop = 3
vim.opt.expandtab = true

vim.opt.colorcolumn = "128"

vim.opt.listchars = { space = "·", tab = "»·", trail = "·", nbsp = "␣" }
vim.api.nvim_create_autocmd("ModeChanged", {
    callback = function()
        local mode = vim.fn.mode()
        vim.wo.list = (mode == "v" or mode == "V" or mode == "\22")
    end,
})

vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 8
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.cursorline = true

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
