local config = require("taskmd.config")
local date = require("taskmd.utils.date")

local M = {}

---@class TaskMDTask
---@field task string
---@field date string
---@field scheduled string
---@field due string
---@field recur string
---@field project string
---@field priority string
---@field tags string
---@field uuid? string

---@param uuid string?
---@return string
local function display_uuid(uuid)
    if type(uuid) ~= "string" or uuid == "" then
        return "pending"
    end

    if config.options.short_uuid then
        return uuid:sub(1, 8)
    end

    return uuid
end

---@param recur string
---@return string
local function display_recur(recur)
    local values = {
        yearly = "y",
        monthly = "m",
        weekly = "w",
        daily = "d",
    }

    return values[recur] or recur
end

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

        if not (kind == "due" and display_time == "12:00am") then
            table.insert(parts, "@" .. display_time)
        end

        if left then
            table.insert(parts, "in:" .. left)
        end
    end

    if task.recur ~= "" then
        table.insert(parts, "recur:" .. display_recur(task.recur))
    end

    table.insert(parts, "uuid:" .. display_uuid(task.uuid))

    return table.concat(parts, " ")
end

return M
