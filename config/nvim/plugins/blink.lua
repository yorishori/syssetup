return {
    "saghen/blink.cmp",
    version = "*",
    event = "InsertEnter",
    opts = {
        keymap = {
            preset = "none",
            ["<C-space>"] = { "show", "fallback" },
            ["<CR>"] = { "accept", "fallback" },
            ["<Tab>"] = { "select_next", "fallback" },
            ["<S-Tab>"] = { "select_prev", "fallback" },
            ["<C-e>"] = { "hide", "fallback" },
        },
        completion = {
            trigger = {
                show_on_keyword = false,
                show_on_trigger_character = false,
                show_on_insert_on_trigger_character = false,
                show_on_accept_on_trigger_character = false,
            },
            menu = { auto_show = false },
            documentation = { auto_show = false },
        },
        signature = { enabled = false },
        sources = {
            default = { "lsp", "path", "buffer" },
        },
    },
    opts_extend = { "sources.default" },
}
