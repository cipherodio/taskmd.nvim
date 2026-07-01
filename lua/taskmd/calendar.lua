local date = require("taskmd.utils.date")
local taskwarrior = require("taskmd.taskwarrior")

local M = {}

local ns = vim.api.nvim_create_namespace("taskmd_calendar")

local month_names = {
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
}

local width = 20

local colors = {
    month = "#fe8019",
    weekday = "#fabd2f",
    day = "#ffffff",
    today = "#83a598",
    due = "#fb4934",
    scheduled = "#b8bb26",
    both = "#8ec07c",
}

---@class TaskMDCalendarMark
---@field due? boolean
---@field scheduled? boolean

---@class TaskMDCalendarHighlight
---@field row integer
---@field start_col integer
---@field end_col integer
---@field group string

local function set_highlights()
    vim.api.nvim_set_hl(0, "TaskMDCalendarMonth", {
        fg = colors.month,
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarWeekday", {
        fg = colors.weekday,
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarDay", {
        fg = colors.day,
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarToday", {
        fg = colors.today,
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarDue", {
        fg = colors.due,
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarScheduled", {
        fg = colors.scheduled,
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarBoth", {
        fg = colors.both,
    })
end

---@param text string
---@return string
local function pad(text)
    return text .. string.rep(" ", math.max(0, width - #text))
end

---@param year integer
---@param month integer
---@return integer
local function days_in_month(year, month)
    local time = os.time({
        year = year,
        month = month + 1,
        day = 0,
        hour = 12,
    })

    return tonumber(os.date("%d", time)) or 30
end

---@param year integer
---@param month integer
---@return integer
local function first_weekday(year, month)
    local time = os.time({
        year = year,
        month = month,
        day = 1,
        hour = 12,
    })

    local wday = tonumber(os.date("%w", time)) or 0

    if wday == 0 then
        return 7
    end

    return wday
end

---@param offset integer
---@return integer, integer
local function month_from_now(offset)
    local now = os.date("*t")

    if type(now) ~= "table" then
        return 1970, 1
    end

    local year = tonumber(now.year)
    local month = tonumber(now.month)

    if not (year and month) then
        return 1970, 1
    end

    local time = os.time({
        year = year,
        month = month + offset,
        day = 1,
        hour = 12,
    })

    local result = os.date("*t", time)

    if type(result) ~= "table" then
        return 1970, 1
    end

    local result_year = tonumber(result.year)
    local result_month = tonumber(result.month)

    if not (result_year and result_month) then
        return 1970, 1
    end

    return result_year, result_month
end

---@return string
local function today_key()
    return tostring(os.date("%Y-%m-%d"))
end

---@param value any
---@return string?
local function task_date(value)
    if type(value) ~= "string" then
        return nil
    end

    local task_day = date.from_taskwarrior_datetime(value)

    if task_day then
        return task_day
    end

    local year, month, day = value:match("^(%d%d%d%d)(%d%d)(%d%d)T")

    if year then
        return ("%s-%s-%s"):format(year, month, day)
    end

    year, month, day = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")

    if year then
        return ("%s-%s-%s"):format(year, month, day)
    end

    return nil
end

---@return table<string, TaskMDCalendarMark>
local function task_marks()
    local marks = {}
    local tasks = taskwarrior.pending()

    if not tasks then
        return marks
    end

    for _, task in ipairs(tasks) do
        if type(task) == "table" then
            local due = task_date(task.due)

            if due then
                marks[due] = marks[due] or {}
                marks[due].due = true
            end

            local scheduled = task_date(task.scheduled)

            if scheduled then
                marks[scheduled] = marks[scheduled] or {}
                marks[scheduled].scheduled = true
            end
        end
    end

    return marks
end

---@param key string
---@param today string
---@param marks table<string, TaskMDCalendarMark>
---@return string
local function day_group(key, today, marks)
    local mark = marks[key]

    if mark and mark.due and mark.scheduled then
        return "TaskMDCalendarBoth"
    end

    if mark and mark.due then
        return "TaskMDCalendarDue"
    end

    if mark and mark.scheduled then
        return "TaskMDCalendarScheduled"
    end

    if key == today then
        return "TaskMDCalendarToday"
    end

    return "TaskMDCalendarDay"
end

---@param year integer
---@param month integer
---@param today string
---@param marks table<string, TaskMDCalendarMark>
---@return string[], TaskMDCalendarHighlight[]
local function render_month(year, month, today, marks)
    local lines = {}
    local highlights = {}

    local title = ("%s-%04d"):format(month_names[month], year)

    lines[1] = pad(title)
    lines[2] = "Mo Tu We Th Fr Sa Su"

    table.insert(highlights, {
        row = 0,
        start_col = 0,
        end_col = #title,
        group = "TaskMDCalendarMonth",
    })

    table.insert(highlights, {
        row = 1,
        start_col = 0,
        end_col = width,
        group = "TaskMDCalendarWeekday",
    })

    for i = 1, 6 do
        local days = {}

        for _ = 1, 7 do
            table.insert(days, "  ")
        end

        lines[i + 2] = table.concat(days, " ")
    end

    local first = first_weekday(year, month)
    local count = days_in_month(year, month)

    for day = 1, count do
        local index = first + day - 2
        local week = math.floor(index / 7)
        local weekday = (index % 7) + 1
        local row = week + 3
        local col = (weekday - 1) * 3
        local value = ("%2d"):format(day)

        lines[row] = lines[row]:sub(1, col) .. value .. lines[row]:sub(col + 3)

        local key = ("%04d-%02d-%02d"):format(year, month, day)
        local start_col = col

        if day < 10 then
            start_col = col + 1
        end

        table.insert(highlights, {
            row = row - 1,
            start_col = start_col,
            end_col = col + 2,
            group = day_group(key, today, marks),
        })
    end

    return lines, highlights
end

---@param months string[][]
---@return string[]
local function join_months(months)
    local lines = {}

    for row = 1, 8 do
        table.insert(
            lines,
            ("| %s | %s | %s |"):format(months[1][row], months[2][row], months[3][row])
        )
    end

    return lines
end

---@param highlights TaskMDCalendarHighlight[][]
---@return TaskMDCalendarHighlight[]
local function join_highlights(highlights)
    local joined = {}
    local offsets = {
        2,
        width + 5,
        (width * 2) + 8,
    }

    for month_index, month_highlights in ipairs(highlights) do
        local offset = offsets[month_index]

        for _, highlight in ipairs(month_highlights) do
            table.insert(joined, {
                row = highlight.row,
                start_col = highlight.start_col + offset,
                end_col = highlight.end_col + offset,
                group = highlight.group,
            })
        end
    end

    return joined
end

---@param bufnr integer
---@param highlights TaskMDCalendarHighlight[]
local function apply_highlights(bufnr, highlights)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    for _, highlight in ipairs(highlights) do
        vim.api.nvim_buf_set_extmark(bufnr, ns, highlight.row, highlight.start_col, {
            end_col = highlight.end_col,
            hl_group = highlight.group,
            priority = 200,
        })
    end
end

---@param bufnr integer
local function set_keymaps(bufnr)
    vim.keymap.set("n", "q", "<cmd>close<cr>", {
        buffer = bufnr,
        silent = true,
        nowait = true,
    })

    vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", {
        buffer = bufnr,
        silent = true,
        nowait = true,
    })
end

function M.open()
    set_highlights()

    local marks = task_marks()
    local today = today_key()

    local months = {}
    local highlights = {}

    for i = 0, 2 do
        local year, month = month_from_now(i)
        local month_lines, month_highlights = render_month(year, month, today, marks)

        table.insert(months, month_lines)
        table.insert(highlights, month_highlights)
    end

    local lines = join_months(months)
    local joined_highlights = join_highlights(highlights)

    local bufnr = vim.api.nvim_create_buf(false, true)

    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "taskmd-calendar"

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false

    local ui = vim.api.nvim_list_uis()[1]
    local win_width = #lines[1]
    local win_height = #lines

    local row = math.floor((ui.height - win_height) / 2)
    local col = math.floor((ui.width - win_width) / 2)

    local winid = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = math.max(row, 0),
        col = math.max(col, 0),
        style = "minimal",
        border = "rounded",
    })

    vim.wo[winid].wrap = false
    vim.wo[winid].cursorline = false
    vim.wo[winid].signcolumn = "no"
    vim.wo[winid].number = false
    vim.wo[winid].relativenumber = false

    set_keymaps(bufnr)
    apply_highlights(bufnr, joined_highlights)
end

return M
