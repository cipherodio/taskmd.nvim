local config = require("taskmd.config")

local M = {}

local ns = vim.api.nvim_create_namespace("taskmd_highlight")

local group = vim.api.nvim_create_augroup("taskmd_highlight", {
    clear = true,
})

---@type table<string, string>
local default_colors = {
    scheduled = "#b8bb26",
    due = "#fb4934",
    date = "#fabd2f",
    marker = "#83a598",
    duration = "#689d6a",
    rec = "#d3869b",
    uuid = "#928374",
}

---@return boolean
local function is_enabled()
    local highlight = config.options.highlight

    return highlight ~= nil and highlight.enable ~= false
end

---@param name string
---@return string
local function color(name)
    local highlight = config.options.highlight or {}
    local overrides = highlight.overrides or {}
    local value = overrides[name]

    if type(value) == "string" and value ~= "" then
        return value
    end

    local fallback = default_colors[name]

    if type(fallback) == "string" then
        return fallback
    end

    return "#ffffff"
end

local function set_highlights()
    vim.api.nvim_set_hl(0, "TaskMDScheduled", {
        fg = color("scheduled"),
    })

    vim.api.nvim_set_hl(0, "TaskMDDue", {
        fg = color("due"),
    })

    vim.api.nvim_set_hl(0, "TaskMDDuration", {
        fg = color("duration"),
    })

    vim.api.nvim_set_hl(0, "TaskMDRecur", {
        fg = color("rec"),
    })

    vim.api.nvim_set_hl(0, "TaskMDRecurValue", {
        fg = color("date"),
    })

    vim.api.nvim_set_hl(0, "TaskMDUuid", {
        fg = color("uuid"),
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

---@param line string
---@param from integer
---@return integer?
local function next_marker(line, from)
    local rec_start = line:find("%s+rec:", from)
    local id_start = line:find("%s+id:", from)

    if rec_start and id_start then
        return math.min(rec_start, id_start)
    end

    return rec_start or id_start
end

---@param bufnr integer
---@param row integer
---@param line string
---@param name string
---@param hl_group string
local function highlight_status(bufnr, row, line, name, hl_group)
    local start_pos = line:find(name .. ":")

    if not start_pos then
        return
    end

    local value_start = start_pos + #name + 1
    local value_after = next_marker(line, value_start) or (#line + 1)

    add(bufnr, row, start_pos - 1, value_start - 1, hl_group)
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
    local id_start = line:find("%s+id:", value_start)
    local value_after = id_start or (#line + 1)

    add(bufnr, row, start_pos - 1, value_start - 1, "TaskMDRecur")
    add(bufnr, row, value_start - 1, value_after - 1, "TaskMDRecurValue")
end

---@param bufnr integer
---@param row integer
---@param line string
local function highlight_uuid(bufnr, row, line)
    local start_pos, end_pos = line:find("id:[%w%-]+")

    if not start_pos or not end_pos then
        return
    end

    add(bufnr, row, start_pos - 1, end_pos, "TaskMDUuid")
end

---@param bufnr integer
---@param row integer
---@param line string
local function highlight_line(bufnr, row, line)
    if not line:match("id:") then
        return
    end

    highlight_status(bufnr, row, line, "scheduled", "TaskMDScheduled")
    highlight_status(bufnr, row, line, "due", "TaskMDDue")
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

    if not is_enabled() then
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

    if not is_enabled() then
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
