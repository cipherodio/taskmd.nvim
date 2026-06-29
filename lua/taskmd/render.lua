local date = require("taskmd.utils.date")

local M = {}

---@class TaskMDTask
---@field task string
---@field date string
---@field scheduled string
---@field due string
---@field project string
---@field priority string
---@field tags string
---@field uuid? string

---@param task TaskMDTask
---@return string
function M.line(task)
    local parts = {
        "- " .. task.task,
    }

    local kind
    local time

    if task.scheduled ~= "" then
        kind = "scheduled"
        time = task.scheduled
    elseif task.due ~= "" then
        kind = "due"
        time = task.due
    end

    if kind and task.date ~= "" and time then
        local display_date = date.display_date(task.date)
        local display_time = date.display_time(time)
        local left = date.time_left(task.date, time)

        if display_date then
            table.insert(parts, ("%s:%s"):format(kind, display_date))
        end

        table.insert(parts, "@" .. display_time)

        if left then
            table.insert(parts, "in:" .. left)
        end
    end

    table.insert(parts, "uuid:" .. (task.uuid or "pending"))

    return table.concat(parts, " ")
end

return M
