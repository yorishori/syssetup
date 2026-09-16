return {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus" },
    keys = {
        { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file explorer" },
    },
    init = function()
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        vim.api.nvim_create_autocmd("VimEnter", {
            once = true,
            callback = function()
                local dir = vim.fn.argv(0)
                if dir == "" or vim.fn.isdirectory(dir) ~= 1 then
                    return
                end
                vim.cmd.cd(dir)
                vim.cmd("NvimTreeOpen")
            end,
        })
    end,
    opts = {
        view = { width = 30 },
        renderer = {
            icons = {
                show = {
                    file = true,
                    folder = true,
                    folder_arrow = true,
                    git = false,
                },
            },
        },
        actions = {
            open_file = { quit_on_open = false },
        },
    },
}
