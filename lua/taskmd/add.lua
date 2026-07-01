local render = require("taskmd.render")
local shared = require("taskmd.shared")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

---@param label string
---@return string
local function prompt(label)
    return vim.fn.input(label .. ": ")
end

---@param line string
local function insert_line(line)
    local row = vim.api.nvim_win_get_cursor(0)[1]

    vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, {
        line,
    })
end

function M.create()
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

    insert_line(line)
    shared.write_buffer(0)
end

return M
