local config = require("taskmd.config")

local M = {}

local function check_taskwarrior()
    if vim.fn.executable("task") == 1 then
        vim.health.ok("task command is executable")
    else
        vim.health.error("task command was not found", {
            "Install Taskwarrior.",
            "Make sure the `task` command is available in your PATH.",
        })
    end
end

local function check_keymaps()
    local keymaps = config.options.keymaps

    if not keymaps then
        vim.health.info("No keymaps configured")
        return
    end

    local commands = {
        add = true,
        sync = true,
        delete = true,
        done = true,
        fetch = true,
    }

    for name, lhs in pairs(keymaps) do
        if commands[name] then
            vim.health.ok(("keymap '%s' -> %s"):format(name, lhs))
        else
            vim.health.warn(("unknown keymap command: %s"):format(name))
        end
    end
end

function M.check()
    vim.health.start("taskmd.nvim")

    check_taskwarrior()
    check_keymaps()
end

return M
