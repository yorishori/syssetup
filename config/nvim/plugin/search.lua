-- Pickers (fzf-lua): Ctrl+P files, Ctrl+F text in the project, <leader>? cheatsheet.
-- Inside a picker: type to filter, Enter opens, Esc cancels, Ctrl+Q sends every result to the quickfix list.

vim.pack.add({ "https://github.com/ibhagwan/fzf-lua" })

local fzf = require("fzf-lua")
local open_file = require("open")

-- Enter: open each picked file in its own tab (see lua/open.lua), at the matching line for text search
local function open_selected(selected, opts)
    for _, entry in ipairs(selected) do
        local file = fzf.path.entry_to_file(entry, opts)
        local path = opts.cwd and vim.fs.joinpath(opts.cwd, file.path) or file.path
        open_file.file(path, file.line, file.col)
    end
end

fzf.setup({
    winopts = {
        preview = { layout = "horizontal", horizontal = "right:50%" },
    },
    actions = {
        files = {
            true, -- keep the other default keys (Ctrl+V split, Ctrl+T tab, …)
            ["enter"] = open_selected,
            ["ctrl-q"] = { fn = fzf.actions.file_sel_to_qf, prefix = "select-all" },
        },
    },
    -- Everything except .git: dotfiles and gitignored files included
    files = { hidden = true, no_ignore = true },
    grep = {
        hidden = true,
        no_ignore = true,
        rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -g '!.git' -e",
    },
})

vim.keymap.set("n", "<C-p>", fzf.files, { desc = "Find file by name" })
vim.keymap.set("n", "<C-f>", fzf.live_grep, { desc = "Search text in the project" })

-- Cheatsheet: vanilla commands (lua/cheatsheet.lua) plus every keymap with a readable description
-- (nvim's own keymaps described as ":help …", ":command" or "vim.lsp…" are skipped)
vim.keymap.set("n", "<leader>?", function()
    local entries = {}
    for _, e in ipairs(require("cheatsheet")) do
        table.insert(entries, { section = e[1], desc = e[2], keys = e[3], cmd = e[4] })
    end
    local seen = {}
    for _, mode in ipairs({ "n", "x" }) do
        for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
            local keys = map.lhs:gsub(" ", "<Space>")
            if mode == "x" then keys = keys .. "  (selection)" end
            if map.desc and not map.desc:match("^:") and not map.desc:match("^vim%.")
                and not keys:match("^<Plug>") and not seen[map.desc .. keys] then
                seen[map.desc .. keys] = true
                table.insert(entries, { section = "Keymap", desc = map.desc, keys = keys })
            end
        end
    end

    local lines, by_line = {}, {}
    for _, e in ipairs(entries) do
        local line = string.format("%-9s %-62s %s", e.section, e.desc, fzf.utils.ansi_codes.yellow(e.keys))
        table.insert(lines, line)
        by_line[fzf.utils.strip_ansi_coloring(line)] = e
    end

    fzf.fzf_exec(lines, {
        prompt = "Cheatsheet> ",
        winopts = { preview = { hidden = true } },
        actions = {
            ["enter"] = function(selected)
                local e = selected[1] and by_line[fzf.utils.strip_ansi_coloring(selected[1])]
                if e and e.cmd then
                    vim.api.nvim_feedkeys(e.cmd, "n", false)
                end
            end,
        },
    })
end, { desc = "Cheatsheet: commands and keymaps" })
