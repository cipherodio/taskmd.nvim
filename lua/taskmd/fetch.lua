local date = require("taskmd.utils.date")
local render = require("taskmd.render")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

---@param line string
---@return string?
local function get_uuid(line)
    return line:match("uuid:([%w%-]+)")
end

---@param bufnr integer
---@return table<string, boolean>
local function existing_uuids(bufnr)
    local found = {}
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    for _, line in ipairs(lines) do
        local uuid = get_uuid(line)

        if uuid then
            found[uuid] = true
        end
    end

    return found
end

---@param existing table<string, boolean>
---@param uuid string
---@return boolean
local function has_uuid(existing, uuid)
    for known in pairs(existing) do
        if uuid == known then
            return true
        end

        if uuid:sub(1, #known) == known then
            return true
        end

        if known:sub(1, #uuid) == uuid then
            return true
        end
    end

    return false
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

---@param lines string[]
local function insert_lines(lines)
    local row = vim.api.nvim_win_get_cursor(0)[1]

    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
end

function M.fetch()
    local bufnr = 0
    local existing = existing_uuids(bufnr)
    local tasks = taskwarrior.pending()

    if not tasks then
        return
    end

    local lines = {}

    for _, task in ipairs(tasks) do
        if type(task) == "table" and type(task.uuid) == "string" then
            if not has_uuid(existing, task.uuid) then
                local item = to_item(task)

                if item then
                    table.insert(lines, render.line(item))
                end
            end
        end
    end

    if #lines == 0 then
        vim.notify("TaskMD fetched 0 task(s).")
        return
    end

    insert_lines(lines)

    vim.notify(("TaskMD fetched %d task(s)."):format(#lines))
end

return M
