local M = {}

local add = require("taskmd.add")
local async = require("taskmd.async")
local config = require("taskmd.config")
local sync = require("taskmd.sync")

local cmdlist = {
    add = function()
        add.create()
    end,

    sync = function()
        sync.refresh()
    end,
}

---@param opts? TaskMDOptions
function M.setup(opts)
    config.setup(opts or {})

    local keymaps = config.options.keymaps

    if keymaps then
        for name, lhs in pairs(keymaps) do
            local keymap = cmdlist[name]

            if keymap then
                vim.keymap.set("n", lhs, keymap, {
                    desc = "TaskMD " .. name,
                })
            end
        end
    end

    async.setup()
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
