local date = require("taskmd.utils.date")
local shared = require("taskmd.shared")

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
---@return table<string, any>?
local function get_task(id)
    local result = vim.system({ "task", id, "export" }, {
        text = true,
    }):wait()

    if result.code ~= 0 then
        shared.notify_error(result)
        return nil
    end

    local ok, decoded = pcall(vim.json.decode, result.stdout)

    if not ok or type(decoded) ~= "table" then
        vim.notify("TaskMD: failed to read Taskwarrior JSON.", vim.log.levels.ERROR)
        return nil
    end

    local task = decoded[1] or decoded

    if type(task) ~= "table" then
        return nil
    end

    return task
end

---@param parent table<string, any>
---@return table<string, any>?
local function find_pending_child(parent)
    local parent_uuid = parent.uuid

    if type(parent_uuid) ~= "string" then
        return nil
    end

    local tasks = M.pending()

    if not tasks then
        return nil
    end

    for _, task in ipairs(tasks) do
        if type(task) == "table" and task.parent == parent_uuid then
            return task
        end
    end

    return nil
end

---@param child table<string, any>
---@param parent table<string, any>
local function copy_recur(child, parent)
    if type(child.recur) ~= "string" and type(parent.recur) == "string" then
        child.recur = parent.recur
    end
end

---@param task TaskMDTask
---@return table<string, any>?
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

    if task.due ~= "" then
        if task.date ~= "" then
            local due = date.task_datetime(task.date, task.due)

            if not due then
                vim.notify("TaskMD: invalid due date/time.", vim.log.levels.ERROR)
                return nil
            end

            table.insert(args, "due:" .. due)
        else
            table.insert(args, "due:" .. task.due)
        end
    end

    if task.recur ~= "" then
        table.insert(args, "recur:" .. task.recur)
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
        shared.notify_error(result)
        return nil
    end

    local id = created_id(result.stdout)

    if not id then
        vim.notify("TaskMD: task was created but ID was not found.", vim.log.levels.ERROR)
        return nil
    end

    local created = get_task(id)

    if not created then
        return nil
    end

    if created.status == "recurring" then
        local child = find_pending_child(created)

        if child then
            copy_recur(child, created)
            return child
        end

        return created
    end

    return created
end

---@param uuid string
---@return table<string, any>?
function M.get(uuid)
    local task = get_task(uuid)

    if not task then
        return nil
    end

    if type(task.recur) ~= "string" and type(task.parent) == "string" then
        local parent = get_task(task.parent)

        if parent then
            copy_recur(task, parent)
        end
    end

    return task
end

---@param uuid string
---@return boolean
function M.delete(uuid)
    local result = vim.system({
        "task",
        "rc.confirmation=off",
        uuid,
        "delete",
    }, {
        text = true,
    }):wait()

    if result.code ~= 0 then
        shared.notify_error(result)
        return false
    end

    return true
end

---@return table[]?
function M.pending()
    local result = vim.system({
        "task",
        "status:pending",
        "export",
    }, {
        text = true,
    }):wait()

    if result.code ~= 0 then
        shared.notify_error(result)
        return nil
    end

    if type(result.stdout) ~= "string" or result.stdout == "" then
        vim.notify("TaskMD: Taskwarrior returned no tasks.", vim.log.levels.ERROR)
        return nil
    end

    local ok, decoded = pcall(vim.json.decode, result.stdout)

    if not ok or type(decoded) ~= "table" then
        vim.notify("TaskMD: failed to read Taskwarrior JSON.", vim.log.levels.ERROR)
        return nil
    end

    return decoded
end

return M
