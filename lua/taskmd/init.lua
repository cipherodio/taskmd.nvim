local M = {}

local add = require("taskmd.add")
local sync = require("taskmd.sync")

local cmdlist = {
    add = function()
        add.create()
    end,

    sync = function()
        sync.refresh()
    end,
}

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
