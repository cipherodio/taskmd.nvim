local M = {}

---@param result vim.SystemCompleted
function M.notify_error(result)
    local message = result.stderr

    if type(message) ~= "string" or message == "" then
        message = result.stdout
    end

    if type(message) ~= "string" or message == "" then
        message = "TaskMD: Taskwarrior command failed."
    end

    vim.notify(message, vim.log.levels.ERROR)
end

return M
