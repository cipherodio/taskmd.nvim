---@class TaskMDSyncOnOpenOptions
---@field enable? boolean
---@field autowrite? boolean

---@class TaskMDOptions
---@field sync_on_open? TaskMDSyncOnOpenOptions
---@field file_path? string|string[]
---@field short_uuid? boolean
---@field write_on_command? boolean
---@field highlight? boolean
---@field keymaps? table<string, string>

local M = {}

---@type TaskMDOptions
M.options = {
    sync_on_open = {
        enable = false,
        autowrite = false,
    },

    file_path = nil,
    short_uuid = false,
    write_on_command = false,
    highlight = true,
}

---@param opts? TaskMDOptions
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
