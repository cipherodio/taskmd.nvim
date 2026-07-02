local config = require("taskmd.config")
local path = require("taskmd.utils.path")
local shared = require("taskmd.shared")
local sync = require("taskmd.sync")

local M = {}

---@type table<integer, boolean>
local synced = {}

local group = vim.api.nvim_create_augroup("taskmd_sync_on_open", {
    clear = true,
})

---@param bufnr integer
---@return boolean
local function should_sync(bufnr)
    local sync_on_open = config.options.sync_on_open

    if not sync_on_open or not sync_on_open.enable then
        return false
    end

    return path.is_inside_root(bufnr)
end

---@param bufnr integer
local function sync_buffer(bufnr)
    if synced[bufnr] then
        return
    end

    if not should_sync(bufnr) then
        return
    end

    synced[bufnr] = true

    vim.defer_fn(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end

        if not should_sync(bufnr) then
            return
        end

        local was_modified = vim.bo[bufnr].modified

        sync.refresh({
            bufnr = bufnr,
            quiet = true,
        })

        if not was_modified and vim.api.nvim_buf_is_valid(bufnr) then
            local sync_on_open = config.options.sync_on_open

            if sync_on_open and sync_on_open.autowrite then
                shared.write_buffer(bufnr, true)
            else
                vim.bo[bufnr].modified = false
            end
        end
    end, 100)
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
