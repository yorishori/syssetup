vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.termguicolors = true

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    spec = {
        { import = "plugins" },
    },
    install = { colorscheme = { "habamax" } },
    checker = { enabled = true, notify = false },
})

local stamp_file = vim.fn.stdpath("state") .. "/lazy-auto-update-stamp"
local function should_update()
    local stamp = io.open(stamp_file, "r")
    if not stamp then
        return true
    end
    local last = tonumber(stamp:read("*a")) or 0
    stamp:close()
    return (os.time() - last) > (24 * 60 * 60)
end

if should_update() then
    vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
            require("lazy").sync({ show = false })
            local stamp = io.open(stamp_file, "w")
            if stamp then
                stamp:write(tostring(os.time()))
                stamp:close()
            end
        end,
    })
end
