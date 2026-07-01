local render = require("taskmd.render")
local shared = require("taskmd.shared")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

---@param line string
---@return string?
local function get_uuid(line)
    return line:match("id:([%w%-]+)")
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
---@field write? boolean

---@param opts? TaskMDSyncOptions
function M.refresh(opts)
    opts = opts or {}

    local bufnr = opts.bufnr or 0
    local changed = update_buffer(bufnr, update_from_taskwarrior)

    if not opts.quiet then
        vim.notify(("TaskMD synced %d task(s)."):format(changed))
    end

    if opts.write then
        shared.write_buffer(bufnr)
    end
end

return M
