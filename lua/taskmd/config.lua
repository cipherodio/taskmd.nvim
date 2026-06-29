---@class TaskMDOptions
---@field task_command? string
---@field keymaps? table<string, string>

local M = {}

---@type TaskMDOptions
M.options = {
    task_command = "task",
}

---@param opts? TaskMDOptions
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

---@return string
function M.task_command()
    return M.options.task_command or "task"
end

return M
