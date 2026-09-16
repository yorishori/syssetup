return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local ts = require("nvim-treesitter")

        ts.install({
            "bash", "c", "cpp", "css", "html", "javascript", "json",
            "lua", "luadoc", "markdown", "markdown_inline", "python",
            "query", "regex", "tsx", "typescript", "vim", "vimdoc", "yaml",
        })

        local available = ts.get_available()

        vim.api.nvim_create_autocmd("FileType", {
            callback = function(event)
                local lang = vim.treesitter.language.get_lang(event.match) or event.match
                if not vim.treesitter.language.add(lang) then
                    if vim.tbl_contains(available, lang) then
                        ts.install({ lang })
                    end
                    return
                end
                pcall(vim.treesitter.start, event.buf, lang)
            end,
        })
    end,
}
