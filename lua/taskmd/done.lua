local shared = require("taskmd.shared")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

---@param line string
---@return string?
local function get_uuid(line)
    return line:match("uuid:([%w%-]+)")
end

function M.done()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_get_current_line()
    local uuid = get_uuid(line)

    if not uuid then
        vim.notify("TaskMD: no uuid found on current line.", vim.log.levels.ERROR)
        return
    end

    local choice =
        vim.fn.confirm(("Mark Taskwarrior task %s as done?"):format(uuid), "&Yes\n&No", 2)

    if choice ~= 1 then
        return
    end

    local ok = taskwarrior.done(uuid)

    if not ok then
        return
    end

    vim.api.nvim_buf_set_lines(0, row - 1, row, false, {})
    shared.write_buffer(0)

    vim.notify("TaskMD completed task: " .. uuid)
end

return M
