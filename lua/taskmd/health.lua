local config = require("taskmd.config")
local path = require("taskmd.utils.path")

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

local function check_paths()
    local root_dir = path.root_dir()

    if root_dir then
        if vim.fn.isdirectory(root_dir) == 1 then
            vim.health.ok("root_dir: " .. root_dir)
        else
            vim.health.warn("root_dir does not exist: " .. root_dir)
        end
    else
        vim.health.error("root_dir is not configured")
    end

    local task_file = path.task_file()

    if task_file then
        if vim.fn.filereadable(task_file) == 1 then
            vim.health.ok("task_file: " .. task_file)
        else
            vim.health.warn("task_file does not exist yet: " .. task_file)
        end
    else
        vim.health.error("task_file is not configured")
    end

    local scan_dirs = path.scan_dirs()

    if #scan_dirs == 0 then
        vim.health.info("scan_dir is not configured")
        return
    end

    for _, scan_dir in ipairs(scan_dirs) do
        if vim.fn.isdirectory(scan_dir) == 1 then
            vim.health.ok("scan_dir: " .. scan_dir)
        else
            vim.health.warn("scan_dir does not exist: " .. scan_dir)
        end
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
        calendar = true,
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
    check_paths()
    check_keymaps()
end

return M
