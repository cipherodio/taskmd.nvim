local config = require("taskmd.config")
local sync = require("taskmd.sync")

local M = {}

---@type table<integer, boolean>
local synced = {}

local group = vim.api.nvim_create_augroup("taskmd_sync_on_open", {
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
    if not config.options.sync_on_open then
        return false
    end

    local file_path = config.options.file_path

    if not file_path then
        return false
    end

    local name = vim.api.nvim_buf_get_name(bufnr)

    if name == "" then
        return false
    end

    local current = normalize(name)

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
local function sync_buffer(bufnr)
    if synced[bufnr] then
        return
    end

    if not matches_file(bufnr) then
        return
    end

    sync.refresh({
        bufnr = bufnr,
        quiet = true,
    })

    synced[bufnr] = true
end

function M.setup()
    vim.api.nvim_clear_autocmds({
        group = group,
    })

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
        group = group,
        callback = function(args)
            sync_buffer(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = group,
        callback = function(args)
            synced[args.buf] = nil
        end,
    })
end

return M
