local date = require("taskmd.utils.date")

local M = {}

---@param text string
---@return string[]
local function split_tags(text)
    local tags = {}

    for tag in text:gmatch("%S+") do
        table.insert(tags, "+" .. tag)
    end

    return tags
end

---@param output string
---@return string?
local function created_id(output)
    return output:match("Created task (%d+)")
end

---@param id string
---@return string?
local function get_uuid(id)
    local result = vim.system({ "task", id, "export" }, {
        text = true,
    }):wait()

    if result.code ~= 0 then
        vim.notify(result.stderr, vim.log.levels.ERROR)
        return nil
    end

    local ok, decoded = pcall(vim.json.decode, result.stdout)

    if not ok then
        vim.notify("TaskMD: failed to read Taskwarrior JSON.", vim.log.levels.ERROR)
        return nil
    end

    local task = decoded[1] or decoded

    return task.uuid
end

---@param task TaskMDTask
---@return string?
function M.add(task)
    local args = {
        "task",
        "add",
        task.task,
    }

    if task.date ~= "" and task.scheduled ~= "" then
        local scheduled = date.task_datetime(task.date, task.scheduled)

        if not scheduled then
            vim.notify("TaskMD: invalid scheduled date/time.", vim.log.levels.ERROR)
            return nil
        end

        table.insert(args, "scheduled:" .. scheduled)
    end

    if task.date ~= "" and task.due ~= "" then
        local due = date.task_datetime(task.date, task.due)

        if not due then
            vim.notify("TaskMD: invalid due date/time.", vim.log.levels.ERROR)
            return nil
        end

        table.insert(args, "due:" .. due)
    end

    if task.project ~= "" then
        table.insert(args, "project:" .. task.project)
    end

    if task.priority ~= "" then
        table.insert(args, "priority:" .. task.priority)
    end

    if task.tags ~= "" then
        vim.list_extend(args, split_tags(task.tags))
    end

    local result = vim.system(args, {
        text = true,
    }):wait()

    if result.code ~= 0 then
        vim.notify(result.stderr, vim.log.levels.ERROR)
        return nil
    end

    local id = created_id(result.stdout)

    if not id then
        vim.notify("TaskMD: task was created but ID was not found.", vim.log.levels.ERROR)
        return nil
    end

    return get_uuid(id)
end

---@param uuid string
---@return table<string, any>?
function M.get(uuid)
    local result = vim.system({ "task", uuid, "export" }, {
        text = true,
    }):wait()

    if result.code ~= 0 then
        vim.notify(result.stderr, vim.log.levels.ERROR)
        return nil
    end

    local ok, decoded = pcall(vim.json.decode, result.stdout)

    if not ok or type(decoded) ~= "table" then
        vim.notify("TaskMD: failed to read Taskwarrior JSON.", vim.log.levels.ERROR)
        return nil
    end

    local task = decoded[1]

    if type(task) ~= "table" then
        return nil
    end

    return task
end

return M
