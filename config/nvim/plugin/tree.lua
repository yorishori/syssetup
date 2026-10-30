-- File tree sidebar (nvim-tree), toggled with Ctrl+B. Inside the tree, g? lists every key.

-- nvim-tree replaces netrw, the built-in file browser
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.pack.add({
    "https://github.com/nvim-tree/nvim-tree.lua",
    "https://github.com/nvim-tree/nvim-web-devicons", -- file icons
})

local api = require("nvim-tree.api")

local function is_empty_buffer(buf)
    return vim.api.nvim_buf_get_name(buf) == ""
        and vim.bo[buf].buftype == ""
        and not vim.bo[buf].modified
        and vim.api.nvim_buf_line_count(buf) == 1
        and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
end

-- Like VSCode: jump to the file's tab if it's already open, use this tab if it's empty, otherwise open a new tab.
-- Folders expand/collapse.
local function open()
    local node = api.tree.get_node_under_cursor()
    if not node then return end
    if node.type ~= "file" and not (node.type == "link" and not node.nodes) then
        api.node.open.edit(node)
        return
    end
    local others = vim.tbl_filter(function(win)
        return not api.tree.is_tree_buf(vim.api.nvim_win_get_buf(win))
    end, vim.api.nvim_tabpage_list_wins(0))
    local already_open = vim.fn.bufwinid(node.absolute_path) ~= -1
    if not already_open and #others == 1 and is_empty_buffer(vim.api.nvim_win_get_buf(others[1])) then
        api.node.open.edit(node)
    else
        api.node.open.tab_drop(node)
    end
end

-- l: open a file / expand a folder (or step into it if it's already expanded)
local function expand()
    local node = api.tree.get_node_under_cursor()
    if node and node.nodes and node.open then
        vim.cmd.normal({ "j", bang = true })
    else
        open()
    end
end

-- h: collapse the folder, or jump to the parent folder and collapse it
local function collapse()
    local node = api.tree.get_node_under_cursor()
    if node and node.nodes and node.open then
        api.node.open.edit(node)
    else
        api.node.navigate.parent_close(node)
    end
end

-- Right click: open the clicked file in a split next to the current one
local function open_split()
    local mouse = vim.fn.getmousepos()
    if mouse.winid ~= vim.api.nvim_get_current_win() or mouse.line == 0 then return end
    vim.api.nvim_win_set_cursor(0, { mouse.line, 0 })
    local node = api.tree.get_node_under_cursor()
    if node and not node.nodes then
        api.node.open.vertical(node)
    end
end

local function on_attach(bufnr)
    api.map.on_attach.default(bufnr)

    local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, nowait = true, desc = "nvim-tree: " .. desc })
    end
    map("<CR>", open, "Open")
    map("o", open, "Open")
    map("<2-LeftMouse>", open, "Open")
    map("l", expand, "Open / expand")
    map("h", collapse, "Collapse")
    map("<RightMouse>", open_split, "Open in split")
end

require("nvim-tree").setup({
    on_attach = on_attach,
    hijack_directories = { enable = false }, -- `nvim .` opens the sidebar instead (see VimEnter below)
    update_focused_file = { enable = true }, -- reveal the current file in the tree
    tab = { sync = { open = true, close = true } }, -- same tree in every tab
    modified = { enable = true }, -- ● after files with unsaved changes
    filters = { git_ignored = false }, -- show everything, gitignored included
    renderer = {
        highlight_git = "name",
        icons = { show = { git = false } },
    },
})

-- Git coloring is only used to grey out gitignored files: clear every other git status color
local function mute_git_colors()
    for _, status in ipairs({ "Deleted", "Dirty", "Merge", "New", "Renamed", "Staged" }) do
        vim.api.nvim_set_hl(0, "NvimTreeGitFile" .. status .. "HL", {})
        vim.api.nvim_set_hl(0, "NvimTreeGitFolder" .. status .. "HL", {})
    end
end
mute_git_colors()
vim.api.nvim_create_autocmd("ColorScheme", { callback = mute_git_colors })

-- Ctrl+B: show the tree / jump into it / hide it
vim.keymap.set("n", "<C-b>", function()
    if api.tree.is_tree_buf() then
        api.tree.close()
    elseif api.tree.is_visible() then
        api.tree.focus()
    else
        api.tree.open()
    end
end, { desc = "File tree: show / focus / hide" })

-- Open the tree on `nvim <directory>` or plain `nvim`
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local arg = vim.fn.argv(0)
        if vim.fn.argc() == 0 and is_empty_buffer(0) then
            api.tree.open()
        elseif vim.fn.argc() == 1 and vim.fn.isdirectory(arg) == 1 then
            local dir_buf = vim.api.nvim_get_current_buf()
            vim.cmd.enew()
            vim.api.nvim_buf_delete(dir_buf, { force = true })
            vim.cmd.cd(arg)
            api.tree.open()
        end
    end,
})

-- Closing the last file in a tab closes the tab too, instead of leaving the tree alone in it
vim.api.nvim_create_autocmd("QuitPre", {
    callback = function()
        if api.tree.is_tree_buf() then return end
        local wins = vim.tbl_filter(function(win)
            return vim.api.nvim_win_get_config(win).relative == ""
        end, vim.api.nvim_tabpage_list_wins(0))
        if #wins == 2 and api.tree.is_visible() then
            api.tree.close_in_this_tab()
        end
    end,
})
