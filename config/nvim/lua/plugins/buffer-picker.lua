-- Fuzzy pickers for buffers, files and text
return {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
        {
            "<leader><Tab>",
            function() require("telescope.builtin").buffers() end,
            desc = "Select buffer",
        },
        {
            "<leader>f",
            function() require("telescope.builtin").find_files() end,
            desc = "Find file",
        },
        {
            "<leader>/",
            function() require("telescope.builtin").live_grep() end,
            desc = "Grep project",
        },
    },
}
