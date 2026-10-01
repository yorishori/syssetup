-- Shows what keys do: a hint popup after a prefix (g, z, ], <leader>, ...)
-- and every keymap, built-in or not, on <leader><leader>
return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
        {
            "<leader><leader>",
            function() require("which-key").show({ global = true }) end,
            desc = "Show all keymaps",
        },
    },
}
