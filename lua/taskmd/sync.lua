local path = require("taskmd.utils.path")
local render = require("taskmd.render")
local shared = require("taskmd.shared")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

---@class TaskMDSyncTarget
---@field bufnr integer
---@field force_write boolean

---@param line string
---@return string?
local function get_uuid(line)
    return line:match("id:([%w%-]+)")
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

---@param bufnr integer
---@return TaskMDSyncTarget?
local function target(bufnr)
    if path.is_inside_root(bufnr) then
        return {
            bufnr = bufnr,
            force_write = false,
        }
    end

    local task_file = path.task_file()

    if not task_file then
        vim.notify("TaskMD: task_file is not configured.", vim.log.levels.ERROR)
        return nil
    end

    local task_bufnr = load_file_buffer(task_file)

    if not task_bufnr then
        return nil
    end

    return {
        bufnr = task_bufnr,
        force_write = true,
    }
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

    local target_file = target(opts.bufnr or 0)

    if not target_file then
        return
    end

    if vim.bo[target_file.bufnr].readonly or not vim.bo[target_file.bufnr].modifiable then
        vim.notify("TaskMD: target file is not writable.", vim.log.levels.ERROR)
        return
    end

    local changed = update_buffer(target_file.bufnr, update_from_taskwarrior)

    if not opts.quiet then
        vim.notify(("TaskMD synced %d task(s)."):format(changed))
    end

    if opts.write then
        shared.write_buffer(target_file.bufnr, target_file.force_write)
    end
end

return M
