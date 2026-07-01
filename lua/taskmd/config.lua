---@class TaskMDSyncOnOpenOptions
---@field enable? boolean
---@field autowrite? boolean

---@class TaskMDFileOutputHighlightOverrides
---@field scheduled? string
---@field due? string
---@field duration? string
---@field rec? string
---@field rec_value? string
---@field id? string

---@class TaskMDFileOutputHighlightOptions
---@field enable? boolean
---@field overrides? TaskMDFileOutputHighlightOverrides

---@class TaskMDCalendarHighlightOverrides
---@field month? string
---@field weekday? string
---@field day? string
---@field today? string
---@field due? string
---@field scheduled? string
---@field sched_due? string

---@class TaskMDCalendarHighlightOptions
---@field overrides? TaskMDCalendarHighlightOverrides

---@class TaskMDHighlightOptions
---@field file_output? TaskMDFileOutputHighlightOptions
---@field calendar? TaskMDCalendarHighlightOptions

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
        file_output = {
            enable = true,
            overrides = {},
        },

        calendar = {
            overrides = {},
        },
    },
}

---@param opts? TaskMDOptions
function M.setup(opts)
    M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
