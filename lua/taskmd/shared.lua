local date = require("taskmd.utils.date")

local M = {}

---@param result vim.SystemCompleted
function M.notify_error(result)
    local message = result.stderr

    if type(message) ~= "string" or message == "" then
        message = result.stdout
    end

    if type(message) ~= "string" or message == "" then
        message = "TaskMD: Taskwarrior command failed."
    end

    vim.notify(message, vim.log.levels.ERROR)
end

---@param task table<string, any>
---@return TaskMDTask?
function M.to_item(task)
    local description = task.description

    if type(description) ~= "string" or description == "" then
        return nil
    end

    ---@type TaskMDTask
    local item = {
        task = description,
        date = "",
        scheduled = "",
        due = "",
        recur = "",
        project = "",
        priority = "",
        tags = "",
        uuid = type(task.uuid) == "string" and task.uuid or nil,
    }

    if type(task.project) == "string" then
        item.project = task.project
    end

    if type(task.priority) == "string" then
        item.priority = task.priority
    end

    if type(task.recur) == "string" then
        item.recur = task.recur
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

return M
