---@class TaskMDAsyncOptions
---@field enabled? boolean
---@field rate? integer
---@field file_path? string|string[]

---@class TaskMDOptions
---@field async? TaskMDAsyncOptions
---@field short_uuid? boolean
---@field keymaps? table<string, string>

local M = {}

---@type TaskMDOptions
M.options = {
    async = {
        enabled = false,
        rate = 1,
        file_path = nil,
    },

    short_uuid = false,
}

---@param opts? TaskMDOptions
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
