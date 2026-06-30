---@class TaskMDSyncOnOpenOptions
---@field enable? boolean
---@field autowrite? boolean

---@class TaskMDHighlightOverrides
---@field scheduled? string
---@field due? string
---@field date? string
---@field marker? string
---@field duration? string
---@field rec? string
---@field uuid? string

---@class TaskMDHighlightOptions
---@field enable? boolean
---@field overrides? TaskMDHighlightOverrides

---@class TaskMDOptions
---@field sync_on_open? TaskMDSyncOnOpenOptions
---@field file_path? string|string[]
---@field short_uuid? boolean
---@field write_on_command? boolean
---@field highlight? TaskMDHighlightOptions
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

    highlight = {
        enable = true,
        overrides = {},
    },
}

---@param opts? TaskMDOptions
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
