-- yazi as the file explorer, also when opening a directory (nvim .)
return {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
        { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
        { "<leader>e", mode = { "n", "v" }, "<cmd>Yazi<cr>", desc = "File explorer (current file)" },
        { "<leader>E", "<cmd>Yazi cwd<cr>", desc = "File explorer (working directory)" },
    },
    opts = {
        open_for_directories = true,
    },
    init = function()
        vim.g.loaded_netrwPlugin = 1
    end,
}
