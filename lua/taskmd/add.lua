local render = require("taskmd.render")
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

    local item = {
        task = task,
        date = prompt("Date"),
        scheduled = prompt("Scheduled"),
        due = prompt("Due"),
        project = prompt("Project"),
        priority = prompt("Priority"),
        tags = prompt("Tags"),
    }

    local uuid = taskwarrior.add(item)

    if not uuid then
        return
    end

    item.uuid = uuid

    local line = render.line(item)

    insert_line(line)
end

return M
