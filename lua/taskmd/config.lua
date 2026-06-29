---@class TaskMDOptions
---@field short_uuid? boolean
---@field keymaps? table<string, string>

local M = {}

---@type TaskMDOptions
M.options = {
    short_uuid = false,
}

---@param opts? TaskMDOptions
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
