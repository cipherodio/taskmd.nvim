local config = require("taskmd.config")
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

---@param bufnr? integer
---@param force? boolean
function M.write_buffer(bufnr, force)
    if not force and not config.options.write_on_command then
        return
    end

    bufnr = bufnr or 0

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    if vim.api.nvim_buf_get_name(bufnr) == "" then
        return
    end

    if vim.bo[bufnr].readonly or not vim.bo[bufnr].modifiable then
        return
    end

    if not vim.bo[bufnr].modified then
        return
    end

    local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function()
        vim.cmd("silent noautocmd write")
    end)

    if not ok then
        vim.notify(
            ("TaskMD: failed to write buffer: %s"):format(tostring(err)),
            vim.log.levels.ERROR
        )
    end
end

return M
