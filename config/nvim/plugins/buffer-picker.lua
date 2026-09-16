return {
    "nvim-telescope/telescope.nvim",
    keys = {
        {
            "<leader><Tab>",
            function() require("telescope.builtin").buffers() end,
            desc = "Select buffer",
        },
    },
}
