local config = require("taskmd.config")

local M = {}

local ns = vim.api.nvim_create_namespace("taskmd_highlight")

local group = vim.api.nvim_create_augroup("taskmd_highlight", {
    clear = true,
})

local function set_highlights()
    vim.api.nvim_set_hl(0, "TaskMDScheduled", {
        fg = "#b8bb26",
        default = true,
    })

    vim.api.nvim_set_hl(0, "TaskMDDue", {
        fg = "#fb4934",
        default = true,
    })

    vim.api.nvim_set_hl(0, "TaskMDDate", {
        fg = "#fabd2f",
        default = true,
    })

    vim.api.nvim_set_hl(0, "TaskMDAt", {
        fg = "#83a598",
        default = true,
    })

    vim.api.nvim_set_hl(0, "TaskMDTime", {
        fg = "#fabd2f",
        default = true,
    })

    vim.api.nvim_set_hl(0, "TaskMDIn", {
        fg = "#83a598",
        default = true,
    })

    vim.api.nvim_set_hl(0, "TaskMDDuration", {
        fg = "#689d6a",
        default = true,
    })

    vim.api.nvim_set_hl(0, "TaskMDRecur", {
        fg = "#d3869b",
        default = true,
    })

    vim.api.nvim_set_hl(0, "TaskMDRecurValue", {
        fg = "#fabd2f",
        default = true,
    })

    vim.api.nvim_set_hl(0, "TaskMDUuid", {
        fg = "#928374",
        default = true,
    })
end

---@param bufnr integer
---@param row integer
---@param start_col integer
---@param end_col integer
---@param hl_group string
local function add(bufnr, row, start_col, end_col, hl_group)
    if end_col <= start_col then
        return
    end

    vim.api.nvim_buf_set_extmark(bufnr, ns, row, start_col, {
        end_col = end_col,
        hl_group = hl_group,
        priority = 200,
    })
end

---@param bufnr integer
---@param row integer
---@param line string
---@param name string
---@param hl_group string
local function highlight_date_field(bufnr, row, line, name, hl_group)
    local start_pos, _, date_start, _, date_after =
        line:find(name .. ":()([a-z]+%-%d%d%-%d%d%d%d)()")

    if not start_pos then
        return
    end

    add(bufnr, row, start_pos - 1, start_pos + #name, hl_group)
    add(bufnr, row, date_start - 1, date_after - 1, "TaskMDDate")
end

---@param bufnr integer
---@param row integer
---@param line string
local function highlight_time(bufnr, row, line)
    local start_pos, _, time = line:find("@(%d+:%d%d[ap]m)")

    if not start_pos then
        return
    end

    add(bufnr, row, start_pos - 1, start_pos, "TaskMDAt")
    add(bufnr, row, start_pos, start_pos + #time, "TaskMDTime")
end

---@param line string
---@param from integer
---@return integer?
local function next_marker(line, from)
    local recur_start = line:find("%s+recur:", from)
    local uuid_start = line:find("%s+uuid:", from)

    if recur_start and uuid_start then
        return math.min(recur_start, uuid_start)
    end

    return recur_start or uuid_start
end

---@param bufnr integer
---@param row integer
---@param line string
local function highlight_in(bufnr, row, line)
    local start_pos = line:find("in:")

    if not start_pos then
        return
    end

    local value_start = start_pos + 3
    local value_after = next_marker(line, value_start) or (#line + 1)

    add(bufnr, row, start_pos - 1, value_start - 1, "TaskMDIn")
    add(bufnr, row, value_start - 1, value_after - 1, "TaskMDDuration")
end

---@param bufnr integer
---@param row integer
---@param line string
local function highlight_recur(bufnr, row, line)
    local start_pos = line:find("rec:")

    if not start_pos then
        return
    end

    local value_start = start_pos + 4
    local uuid_start = line:find("%s+uuid:", value_start)
    local value_after = uuid_start or (#line + 1)

    add(bufnr, row, start_pos - 1, value_start - 1, "TaskMDRecur")
    add(bufnr, row, value_start - 1, value_after - 1, "TaskMDRecurValue")
end

---@param bufnr integer
---@param row integer
---@param line string
local function highlight_uuid(bufnr, row, line)
    local start_pos, end_pos = line:find("uuid:[%w%-]+")

    if not start_pos or not end_pos then
        return
    end

    add(bufnr, row, start_pos - 1, end_pos, "TaskMDUuid")
end

---@param bufnr integer
---@param row integer
---@param line string
local function highlight_line(bufnr, row, line)
    if not line:match("uuid:") then
        return
    end

    highlight_date_field(bufnr, row, line, "scheduled", "TaskMDScheduled")
    highlight_date_field(bufnr, row, line, "due", "TaskMDDue")
    highlight_time(bufnr, row, line)
    highlight_in(bufnr, row, line)
    highlight_recur(bufnr, row, line)
    highlight_uuid(bufnr, row, line)
end

---@param bufnr? integer
function M.refresh(bufnr)
    bufnr = bufnr or 0

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    if not config.options.highlight then
        return
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    for row, line in ipairs(lines) do
        highlight_line(bufnr, row - 1, line)
    end
end

function M.setup()
    vim.api.nvim_clear_autocmds({
        group = group,
    })

    set_highlights()

    if not config.options.highlight then
        return
    end

    vim.api.nvim_create_autocmd({
        "BufEnter",
        "BufWinEnter",
        "TextChanged",
        "TextChangedI",
        "InsertLeave",
    }, {
        group = group,
        callback = function(args)
            M.refresh(args.buf)
        end,
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
            set_highlights()
            M.refresh(0)
        end,
    })

    M.refresh(0)
end

return M
