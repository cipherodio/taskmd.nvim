local path = require("taskmd.utils.path")
local render = require("taskmd.render")
local shared = require("taskmd.shared")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

---@class TaskMDFetchTarget
---@field bufnr integer
---@field append boolean
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

---@return TaskMDFetchTarget?
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

---@param bufnr integer
---@param lines string[]
local function insert_at_cursor(bufnr, lines)
    local row = vim.api.nvim_win_get_cursor(0)[1]

    vim.api.nvim_buf_set_lines(bufnr, row - 1, row - 1, false, lines)
end

---@param bufnr integer
---@param lines string[]
local function append_lines(bufnr, lines)
    local current = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    if #current == 1 and current[1] == "" then
        vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, lines)
        return
    end

    vim.api.nvim_buf_set_lines(bufnr, #current, #current, false, lines)
end

---@param fetch_target TaskMDFetchTarget
---@param lines string[]
local function insert_lines(fetch_target, lines)
    if fetch_target.append then
        append_lines(fetch_target.bufnr, lines)
    else
        insert_at_cursor(fetch_target.bufnr, lines)
    end
end

function M.fetch()
    local fetch_target = target()

    if not fetch_target then
        return
    end

    if
        vim.bo[fetch_target.bufnr].readonly or not vim.bo[fetch_target.bufnr].modifiable
    then
        vim.notify("TaskMD: target file is not writable.", vim.log.levels.ERROR)
        return
    end

    local existing = existing_uuids(fetch_target.bufnr)
    local tasks = taskwarrior.pending()

    if not tasks then
        return
    end

    local lines = {}

    for _, task in ipairs(tasks) do
        if type(task) == "table" and type(task.uuid) == "string" then
            if not has_uuid(existing, task.uuid) then
                local item = shared.to_item(task)

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

    insert_lines(fetch_target, lines)
    shared.write_buffer(fetch_target.bufnr, fetch_target.force_write)

    vim.notify(("TaskMD fetched %d task(s)."):format(#lines))
end

return M
