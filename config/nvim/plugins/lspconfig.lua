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
                map("n", "gr", vim.lsp.buf.references, "Go to references")
                map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
                map("n", "K", vim.lsp.buf.hover, "Hover documentation")
                map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
            end,
        })
    end,
}
