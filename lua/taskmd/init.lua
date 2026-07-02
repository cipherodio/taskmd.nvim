local M = {}

local add = require("taskmd.add")
local calendar = require("taskmd.calendar")
local config = require("taskmd.config")
local done = require("taskmd.done")
local fetch = require("taskmd.fetch")
local highlight = require("taskmd.highlight")
local path = require("taskmd.utils.path")
local remove = require("taskmd.delete")
local sync = require("taskmd.sync")
local sync_on_open = require("taskmd.sync_on_open")

local group = vim.api.nvim_create_augroup("taskmd_keymaps", {
    clear = true,
})

---@type table<integer, boolean>
local mapped_buffers = {}

local cmdlist = {
    add = function()
        add.create()
    end,

    sync = function()
        sync.refresh({
            write = true,
        })
    end,

    delete = function()
        remove.delete()
    end,

    done = function()
        done.done()
    end,

    fetch = function()
        fetch.fetch()
    end,

    calendar = function()
        calendar.open()
    end,
}

local global_keymaps = {
    add = true,
    sync = true,
    fetch = true,
    calendar = true,
}

local buffer_keymaps = {
    delete = true,
    done = true,
}

---@param name string
---@return function?
local function command(name)
    return cmdlist[name]
end

local function setup_global_keymaps()
    local keymaps = config.options.keymaps

    if not keymaps then
        return
    end

    for name, lhs in pairs(keymaps) do
        local keymap = command(name)

        if keymap and global_keymaps[name] then
            vim.keymap.set("n", lhs, keymap, {
                desc = "TaskMD " .. name,
            })
        end
    end
end

---@param bufnr integer
local function setup_buffer_keymaps(bufnr)
    if mapped_buffers[bufnr] then
        return
    end

    if not path.is_task_file(bufnr) then
        return
    end

    local keymaps = config.options.keymaps

    if not keymaps then
        return
    end

    for name, lhs in pairs(keymaps) do
        local keymap = command(name)

        if keymap and buffer_keymaps[name] then
            vim.keymap.set("n", lhs, keymap, {
                buffer = bufnr,
                desc = "TaskMD " .. name,
            })
        end
    end

    mapped_buffers[bufnr] = true
end

local function setup_buffer_keymap_autocmds()
    vim.api.nvim_clear_autocmds({
        group = group,
    })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        group = group,
        callback = function(args)
            setup_buffer_keymaps(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = group,
        callback = function(args)
            mapped_buffers[args.buf] = nil
        end,
    })

    setup_buffer_keymaps(0)
end

---@param opts? TaskMDOptions
function M.setup(opts)
    config.setup(opts or {})

    setup_global_keymaps()
    setup_buffer_keymap_autocmds()

    sync_on_open.setup()
    highlight.setup()
end

vim.api.nvim_create_user_command("TaskMD", function(opts)
    local cmd = cmdlist[opts.fargs[1]]

    if cmd then
        cmd()
    else
        vim.notify(
            ("Unknown TaskMD command: %s"):format(opts.fargs[1]),
            vim.log.levels.ERROR
        )
    end
end, {
    nargs = 1,

    complete = function()
        return vim.tbl_keys(cmdlist)
    end,
})

return M
