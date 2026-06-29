local date = require("taskmd.utils.date")

local M = {}

---@param line string
---@return string?
local function update_line(line)
    if not line:match("uuid:") then
        return nil
    end

    local display_date
    local display_time

    display_date, display_time =
        line:match("scheduled:([a-z]+%-%d%d%-%d%d%d%d)%s+@(%d+:%d%d[ap]m)")

    if not display_date then
        display_date, display_time =
            line:match("due:([a-z]+%-%d%d%-%d%d%d%d)%s+@(%d+:%d%d[ap]m)")
    end

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
