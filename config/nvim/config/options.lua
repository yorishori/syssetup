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
