-- LSP server actions
return {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
        vim.lsp.config("*", {
            capabilities = require("blink.cmp").get_lsp_capabilities(),
        })

        vim.diagnostic.config({
            underline = { severity = { min = vim.diagnostic.severity.ERROR } },
            virtual_text = false,
            virtual_lines = false,
            signs = false,
            float = false,
            update_in_insert = false,
        })

        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
            callback = function(args)
                local map = function(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
                end

                map("n", "gd", vim.lsp.buf.definition, "Go to definition")
                map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
                -- The rest are Neovim defaults: K hover, grr references, gri implementation,
                -- grn rename, gra code action, <C-s> (insert) signature help
            end,
        })
    end,
}
