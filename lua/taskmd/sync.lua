local date = require("taskmd.utils.date")
local render = require("taskmd.render")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

---@param line string
---@return string?
local function get_uuid(line)
    return line:match("uuid:([%w%-]+)")
end

---@param task table<string, any>
---@return TaskMDTask?
local function to_item(task)
    local description = task.description

    if type(description) ~= "string" or description == "" then
        return nil
    end

    local item = {
        task = description,
        date = "",
        scheduled = "",
        due = "",
        project = "",
        priority = "",
        tags = "",
        uuid = task.uuid,
    }

    if type(task.project) == "string" then
        item.project = task.project
    end

    if type(task.priority) == "string" then
        item.priority = task.priority
    end

    if type(task.scheduled) == "string" then
        local task_date, task_time = date.from_taskwarrior_datetime(task.scheduled)

        if task_date and task_time then
            item.date = task_date
            item.scheduled = task_time
        end
    elseif type(task.due) == "string" then
        local task_date, task_time = date.from_taskwarrior_datetime(task.due)

        if task_date and task_time then
            item.date = task_date
            item.due = task_time
        end
    end

    return item
end

---@param line string
---@return string?
local function update_line(line)
    local uuid = get_uuid(line)

    if not uuid then
        return nil
    end

    local task = taskwarrior.get(uuid)

    if not task then
        return nil
    end

    if task.status ~= "pending" then
        return nil
    end

    local item = to_item(task)

    if not item then
        return nil
    end

    return render.line(item)
end

function M.refresh()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local changed = 0

    for i, line in ipairs(lines) do
        local updated = update_line(line)

        if updated and updated ~= line then
            lines[i] = updated
            changed = changed + 1
        end
    end

    if changed > 0 then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    end

    vim.notify(("TaskMD synced %d task(s)."):format(changed))
end

return M
