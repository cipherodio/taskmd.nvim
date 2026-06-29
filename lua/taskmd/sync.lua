local date = require("taskmd.utils.date")
local render = require("taskmd.render")
local shared = require("taskmd.shared")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

---@param line string
---@return string?
local function get_uuid(line)
    return line:match("uuid:([%w%-]+)")
end

---@param line string
---@return string?, string?
local function get_markdown_time(line)
    local display_date
    local display_time

    display_date, display_time =
        line:match("scheduled:([a-z]+%-%d%d%-%d%d%d%d)%s+@(%d+:%d%d[ap]m)")

    if not display_date then
        display_date, display_time =
            line:match("due:([a-z]+%-%d%d%-%d%d%d%d)%s+@(%d+:%d%d[ap]m)")
    end

    return display_date, display_time
end

---@param line string
---@return string?
local function update_time_only(line)
    if not line:match("uuid:") then
        return nil
    end

    local display_date, display_time = get_markdown_time(line)

    if not (display_date and display_time) then
        return nil
    end

    local task_date = date.parse_display_date(display_date)

    if not task_date then
        return nil
    end

    local left = date.time_left(task_date, display_time)

    if not left then
        return nil
    end

    if line:match("%s+in:") then
        return (line:gsub("in:.-%s+uuid:", "in:" .. left .. " uuid:", 1))
    end

    return (line:gsub("%s+uuid:", " in:" .. left .. " uuid:", 1))
end

---@param line string
---@return string?
local function update_from_taskwarrior(line)
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

    local item = shared.to_item(task)

    if not item then
        return nil
    end

    return render.line(item)
end

---@param bufnr integer
---@param updater fun(line: string): string?
---@return integer
local function update_buffer(bufnr, updater)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local changed = 0

    for i, line in ipairs(lines) do
        local updated = updater(line)

        if updated and updated ~= line then
            lines[i] = updated
            changed = changed + 1
        end
    end

    if changed > 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end

    return changed
end

---@class TaskMDSyncOptions
---@field bufnr? integer
---@field quiet? boolean

---@param opts? TaskMDSyncOptions
function M.refresh(opts)
    opts = opts or {}

    local bufnr = opts.bufnr or 0
    local changed = update_buffer(bufnr, update_from_taskwarrior)

    if not opts.quiet then
        vim.notify(("TaskMD synced %d task(s)."):format(changed))
    end
end

---@param opts? TaskMDSyncOptions
function M.refresh_in_buffer(opts)
    opts = opts or {}

    local bufnr = opts.bufnr or 0
    local changed = update_buffer(bufnr, update_time_only)

    if not opts.quiet then
        vim.notify(("TaskMD refreshed %d task timer(s)."):format(changed))
    end
end

return M
