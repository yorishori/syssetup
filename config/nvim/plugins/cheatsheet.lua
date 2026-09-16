return {
    "sudormrfbin/cheatsheet.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/popup.nvim",
        "nvim-lua/plenary.nvim",
    },
    keys = {
        {
            "<leader><leader>",
            "<cmd>Cheatsheet<cr>",
            desc = "Search all shortcuts / commands",
        },
    },
}
