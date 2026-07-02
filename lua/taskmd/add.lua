local path = require("taskmd.utils.path")
local render = require("taskmd.render")
local shared = require("taskmd.shared")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

---@class TaskMDAddTarget
---@field bufnr integer
---@field append boolean
---@field force_write boolean

---@param label string
---@return string
local function prompt(label)
    return vim.fn.input(label .. ": ")
end

---@param file string
---@return integer?
local function load_file_buffer(file)
    local bufnr = vim.fn.bufadd(file)

    if bufnr == 0 then
        vim.notify("TaskMD: failed to create task file buffer.", vim.log.levels.ERROR)
        return nil
    end

    vim.fn.bufload(bufnr)

    if not vim.api.nvim_buf_is_valid(bufnr) then
        vim.notify("TaskMD: invalid task file buffer.", vim.log.levels.ERROR)
        return nil
    end

    return bufnr
end

---@return TaskMDAddTarget?
local function target()
    if path.is_inside_root(0) then
        return {
            bufnr = 0,
            append = false,
            force_write = false,
        }
    end

    local task_file = path.task_file()

    if not task_file then
        vim.notify("TaskMD: task_file is not configured.", vim.log.levels.ERROR)
        return nil
    end

    local bufnr = load_file_buffer(task_file)

    if not bufnr then
        return nil
    end

    return {
        bufnr = bufnr,
        append = true,
        force_write = true,
    }
end

---@param bufnr integer
---@param line string
local function insert_at_cursor(bufnr, line)
    local row = vim.api.nvim_win_get_cursor(0)[1]

    vim.api.nvim_buf_set_lines(bufnr, row - 1, row - 1, false, {
        line,
    })
end

---@param bufnr integer
---@param line string
local function append_line(bufnr, line)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    if #lines == 1 and lines[1] == "" then
        vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, {
            line,
        })
        return
    end

    vim.api.nvim_buf_set_lines(bufnr, #lines, #lines, false, {
        line,
    })
end

---@param add_target TaskMDAddTarget
---@param line string
local function insert_line(add_target, line)
    if add_target.append then
        append_line(add_target.bufnr, line)
    else
        insert_at_cursor(add_target.bufnr, line)
    end
end

function M.create()
    local add_target = target()

    if not add_target then
        return
    end

    if vim.bo[add_target.bufnr].readonly or not vim.bo[add_target.bufnr].modifiable then
        vim.notify("TaskMD: target file is not writable.", vim.log.levels.ERROR)
        return
    end

    local task = prompt("Task")

    if task == "" then
        vim.notify("Task is required.", vim.log.levels.ERROR)
        return
    end

    ---@type TaskMDTask
    local item = {
        task = task,
        date = prompt("Date"),
        scheduled = prompt("Scheduled"),
        due = prompt("Due"),
        recur = prompt("Recur"),
        project = prompt("Project"),
        priority = prompt("Priority"),
        tags = prompt("Tags"),
    }

    local created = taskwarrior.add(item)

    if not created then
        return
    end

    local created_item = shared.to_item(created)

    if not created_item then
        return
    end

    local line = render.line(created_item)

    insert_line(add_target, line)
    shared.write_buffer(add_target.bufnr, add_target.force_write)
end

return M
