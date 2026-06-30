local shared = require("taskmd.shared")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

---@param line string
---@return string?
local function get_uuid(line)
    return line:match("id:([%w%-]+)")
end

function M.delete()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_get_current_line()
    local uuid = get_uuid(line)

    if not uuid then
        vim.notify("TaskMD: no id found on current line.", vim.log.levels.ERROR)
        return
    end

    local choice =
        vim.fn.confirm(("Delete Taskwarrior task %s?"):format(uuid), "&Yes\n&No", 2)

    if choice ~= 1 then
        return
    end

    local ok = taskwarrior.delete(uuid)

    if not ok then
        return
    end

    vim.api.nvim_buf_set_lines(0, row - 1, row, false, {})
    shared.write_buffer(0)

    vim.notify("TaskMD deleted task: " .. uuid)
end

return M
