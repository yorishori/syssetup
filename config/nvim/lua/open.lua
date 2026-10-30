-- Open files like VSCode tabs. Used by the file tree and the pickers.
local M = {}

function M.is_empty_buffer(buf)
    return vim.api.nvim_buf_get_name(buf) == ""
        and vim.bo[buf].buftype == ""
        and not vim.bo[buf].modified
        and vim.api.nvim_buf_line_count(buf) == 1
        and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
end

-- Jump to the file's window if it's already open (in any tab), use this tab if it's empty, otherwise open a new tab.
-- line/col are optional, 1-based.
function M.file(path, line, col)
    path = vim.fn.fnamemodify(path, ":p")
    local target
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == path then
            target = win
            break
        end
    end

    if target then
        vim.api.nvim_set_current_win(target)
    else
        local editors = vim.tbl_filter(function(win)
            return vim.api.nvim_win_get_config(win).relative == ""
                and vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
        end, vim.api.nvim_tabpage_list_wins(0))
        if #editors == 1 and M.is_empty_buffer(vim.api.nvim_win_get_buf(editors[1])) then
            vim.api.nvim_set_current_win(editors[1])
            vim.cmd.edit(vim.fn.fnameescape(path))
        else
            vim.cmd.tabedit(vim.fn.fnameescape(path))
        end
    end

    if line and line > 0 then
        pcall(vim.api.nvim_win_set_cursor, 0, { line, math.max((col or 1) - 1, 0) })
        vim.cmd.normal({ "zz", bang = true })
    end
end

return M
