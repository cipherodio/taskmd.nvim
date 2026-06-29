local config = require("taskmd.config")
local sync = require("taskmd.sync")

local M = {}

local uv = vim.uv or vim.loop

---@type table<integer, any>
local timers = {}

---@type table<integer, boolean>
local synced = {}

local group = vim.api.nvim_create_augroup("taskmd_async", {
    clear = true,
})

---@param value string
---@return string
local function normalize(value)
    return vim.fn.fnamemodify(vim.fn.expand(value), ":p")
end

---@param bufnr integer
---@return boolean
local function matches_file(bufnr)
    local async = config.options.async

    if not async or not async.enabled then
        return false
    end

    local file_path = async.file_path

    if not file_path then
        return false
    end

    local current = normalize(vim.api.nvim_buf_get_name(bufnr))

    if type(file_path) == "string" then
        return current == normalize(file_path)
    end

    if type(file_path) == "table" then
        for _, path in ipairs(file_path) do
            if current == normalize(path) then
                return true
            end
        end
    end

    return false
end

---@param bufnr integer
local function stop_timer(bufnr)
    local timer = timers[bufnr]

    if timer then
        timer:stop()
        timer:close()
        timers[bufnr] = nil
    end

    synced[bufnr] = nil
end

---@return integer
local function interval()
    local async = config.options.async or {}
    local rate = async.rate or 1

    if rate <= 0 then
        return 1000
    end

    return rate * 60 * 1000
end

---@param bufnr integer
local function start_timer(bufnr)
    if timers[bufnr] then
        return
    end

    local timer = uv.new_timer()

    if not timer then
        return
    end

    timers[bufnr] = timer

    local ms = interval()

    timer:start(
        ms,
        ms,
        vim.schedule_wrap(function()
            if not vim.api.nvim_buf_is_valid(bufnr) or not matches_file(bufnr) then
                stop_timer(bufnr)
                return
            end

            sync.refresh_in_buffer({
                bufnr = bufnr,
                quiet = true,
            })
        end)
    )
end

---@param bufnr integer
local function start_for_buffer(bufnr)
    if not matches_file(bufnr) then
        return
    end

    if not synced[bufnr] then
        sync.refresh({
            bufnr = bufnr,
            quiet = true,
        })

        synced[bufnr] = true
    end

    sync.refresh_in_buffer({
        bufnr = bufnr,
        quiet = true,
    })

    start_timer(bufnr)
end

function M.setup()
    vim.api.nvim_clear_autocmds({
        group = group,
    })

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
        group = group,
        callback = function(args)
            start_for_buffer(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd({ "BufUnload", "BufDelete", "BufWipeout" }, {
        group = group,
        callback = function(args)
            stop_timer(args.buf)
        end,
    })
end

return M
