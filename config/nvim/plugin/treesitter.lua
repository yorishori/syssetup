-- Syntax highlighting with tree-sitter (nvim-treesitter installs the parsers).
-- Languages not in the list below are downloaded the first time you open such a file.
-- File types without a tree-sitter parser keep vim's regular syntax highlighting.

-- Parsers must match the plugin's version, so rebuild them whenever the plugin updates
vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(event)
        if event.data.spec.name == "nvim-treesitter" and event.data.kind == "update" then
            if not event.data.active then vim.cmd.packadd("nvim-treesitter") end
            vim.cmd("TSUpdate")
        end
    end,
})

vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })

local ts = require("nvim-treesitter")

-- The languages in this repo, plus the ones nvim itself is written in (help files, vimscript, lua)
ts.install({
    "bash", "ini", "javascript", "json", "lua", "markdown", "markdown_inline",
    "qmljs", "query", "toml", "vim", "vimdoc",
})

local available = ts.get_available()

local function start(buf, lang)
    if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.treesitter.start, buf, lang)
    end
end

vim.api.nvim_create_autocmd("FileType", {
    callback = function(event)
        local lang = vim.treesitter.language.get_lang(event.match) or event.match
        if vim.treesitter.language.add(lang) then
            start(event.buf, lang)
        elseif vim.tbl_contains(available, lang) then
            ts.install({ lang }):await(function(err)
                if not err then vim.schedule(function() start(event.buf, lang) end) end
            end)
        end
    end,
})
