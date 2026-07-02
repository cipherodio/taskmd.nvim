local config = require("taskmd.config")

local M = {}

---@param value string
---@return string
local function trim_slash(value)
    if value == "/" then
        return value
    end

    return (value:gsub("/+$", ""))
end

---@param value string
---@return boolean
local function is_absolute(value)
    return value:sub(1, 1) == "/" or value:sub(1, 1) == "~"
end

---@param value string
---@return string
function M.normalize(value)
    return trim_slash(vim.fn.fnamemodify(vim.fn.expand(value), ":p"))
end

---@return string?
function M.root_dir()
    local root_dir = config.options.root_dir

    if type(root_dir) ~= "string" or root_dir == "" then
        return nil
    end

    return M.normalize(root_dir)
end

---@return string?
function M.task_file()
    local task_file = config.options.task_file

    if type(task_file) ~= "string" or task_file == "" then
        return nil
    end

    if is_absolute(task_file) then
        return M.normalize(task_file)
    end

    local root_dir = M.root_dir()

    if not root_dir then
        return nil
    end

    return M.normalize(root_dir .. "/" .. task_file)
end

---@param bufnr integer
---@return string?
function M.buffer_path(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)

    if name == "" then
        return nil
    end

    return M.normalize(name)
end

---@param file string
---@return boolean
function M.is_inside_root_path(file)
    local root_dir = M.root_dir()

    if not root_dir then
        return false
    end

    local current = M.normalize(file)

    return current == root_dir or current:sub(1, #root_dir + 1) == root_dir .. "/"
end

---@param bufnr integer
---@return boolean
function M.is_inside_root(bufnr)
    local file = M.buffer_path(bufnr)

    if not file then
        return false
    end

    return M.is_inside_root_path(file)
end

---@param bufnr integer
---@return string?
function M.target_file(bufnr)
    local current = M.buffer_path(bufnr)

    if current and M.is_inside_root_path(current) then
        return current
    end

    return M.task_file()
end

return M
