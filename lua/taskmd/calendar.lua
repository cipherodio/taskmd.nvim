local config = require("taskmd.config")
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
local horizontal_padding = 1
local day_seconds = 24 * 60 * 60

---@type table<string, table<string, string>>
local default_colors = {
    dark = {
        foreground = "#ebdbb2",
        background = "#1d2021",
        border = "#504945",

        month = "#fe8019",
        weekday = "#fabd2f",
        day = "#ebdbb2",
        today = "#83a598",
        due = "#fb4934",
        scheduled = "#b8bb26",
        sched_due = "#8ec07c",
        this_week = "#458588",
        week_date = "#fabd2f",
        week_task = "#ebdbb2",
        week_time = "#8ec07c",
    },

    light = {
        foreground = "#3c3836",
        background = "#fbf1c7",
        border = "#d5c4a1",

        month = "#af3a03",
        weekday = "#b57614",
        day = "#3c3836",
        today = "#076678",
        due = "#9d0006",
        scheduled = "#79740e",
        sched_due = "#427b58",
        this_week = "#076678",
        week_date = "#b57614",
        week_task = "#3c3836",
        week_time = "#427b58",
    },
}

---@return "dark"|"light"
local function background()
    if vim.o.background == "light" then
        return "light"
    end

    return "dark"
end

---@param name string
---@return string
local function color(name)
    local highlight = config.options.highlight or {}
    local calendar = highlight.calendar or {}
    local overrides = calendar.overrides or {}
    local value = overrides[name]

    if type(value) == "string" and value ~= "" then
        return value
    end

    local fallback = default_colors[background()][name]

    if type(fallback) == "string" then
        return fallback
    end

    return "NONE"
end

---@return string
local function border()
    local highlight = config.options.highlight or {}
    local calendar = highlight.calendar or {}
    local value = calendar.border

    if type(value) == "string" and value ~= "" then
        return value
    end

    return "rounded"
end

---@class TaskMDCalendarMark
---@field due? boolean
---@field scheduled? boolean

---@class TaskMDCalendarHighlight
---@field row integer
---@field start_col integer
---@field end_col integer
---@field group string

---@class TaskMDCalendarWeekTask
---@field key string
---@field kind string
---@field group string
---@field description string
---@field time? string
---@field minutes integer

local function set_highlights()
    vim.api.nvim_set_hl(0, "TaskMDCalendarFloat", {
        fg = color("foreground"),
        bg = color("background"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarBorder", {
        fg = color("border"),
        bg = color("background"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarMonth", {
        fg = color("month"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarWeekday", {
        fg = color("weekday"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarDay", {
        fg = color("day"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarToday", {
        fg = color("today"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarDue", {
        fg = color("due"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarScheduled", {
        fg = color("scheduled"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarBoth", {
        fg = color("sched_due"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarThisWeek", {
        fg = color("this_week"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarWeekDate", {
        fg = color("week_date"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarWeekTask", {
        fg = color("week_task"),
    })

    vim.api.nvim_set_hl(0, "TaskMDCalendarWeekTime", {
        fg = color("week_time"),
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

---@param time string
---@return integer?
local function time_to_minutes(time)
    local hour, minute, meridiem = time:lower():match("^(%d%d?):(%d%d)([ap]m)$")

    if not (hour and minute and meridiem) then
        return nil
    end

    local hour_number = tonumber(hour)
    local minute_number = tonumber(minute)

    if not (hour_number and minute_number) then
        return nil
    end

    if meridiem == "pm" and hour_number ~= 12 then
        hour_number = hour_number + 12
    end

    if meridiem == "am" and hour_number == 12 then
        hour_number = 0
    end

    return (hour_number * 60) + minute_number
end

---@param value any
---@return string?, integer
local function task_time(value)
    if type(value) ~= "string" then
        return nil, 9999
    end

    local _, local_time = date.from_taskwarrior_datetime(value)

    if local_time then
        return "@" .. local_time, time_to_minutes(local_time) or 9999
    end

    return nil, 9999
end

---@param tasks table[]
---@return table<string, TaskMDCalendarMark>
local function task_marks(tasks)
    local marks = {}

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
            ("%s | %s | %s"):format(months[1][row], months[2][row], months[3][row])
        )
    end

    return lines
end

---@param highlights TaskMDCalendarHighlight[][]
---@return TaskMDCalendarHighlight[]
local function join_highlights(highlights)
    local joined = {}
    local offsets = {
        0,
        width + 3,
        (width * 2) + 6,
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

---@param time integer
---@return string?
local function date_key_from_time(time)
    local result = os.date("*t", time)

    if type(result) ~= "table" then
        return nil
    end

    local year = tonumber(result.year)
    local month = tonumber(result.month)
    local day = tonumber(result.day)

    if not (year and month and day) then
        return nil
    end

    return ("%04d-%02d-%02d"):format(year, month, day)
end

---@return string[], table<string, boolean>
local function current_week()
    local now = os.date("*t")

    if type(now) ~= "table" then
        return {}, {}
    end

    local year = tonumber(now.year)
    local month = tonumber(now.month)
    local day = tonumber(now.day)

    if not (year and month and day) then
        return {}, {}
    end

    local today_time = os.time({
        year = year,
        month = month,
        day = day,
        hour = 12,
    })

    local today = os.date("*t", today_time)

    if type(today) ~= "table" then
        return {}, {}
    end

    local wday = tonumber(today.wday) or 2
    local offset = (wday + 5) % 7
    local monday = today_time - (offset * day_seconds)
    local keys = {}
    local lookup = {}

    for i = 0, 6 do
        local key = date_key_from_time(monday + (i * day_seconds))

        if key then
            table.insert(keys, key)
            lookup[key] = true
        end
    end

    return keys, lookup
end

---@param key string
---@return string
local function display_week_date(key)
    local year, month, day = key:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")

    if not (year and month and day) then
        return key
    end

    local year_number = tonumber(year)
    local month_number = tonumber(month)
    local day_number = tonumber(day)

    if not (year_number and month_number and day_number) then
        return key
    end

    local time = os.time({
        year = year_number,
        month = month_number,
        day = day_number,
        hour = 12,
    })

    local result = os.date("*t", time)

    if type(result) ~= "table" then
        return key
    end

    local month_name = month_names[month_number] or month
    local weekday = tostring(os.date("%A", time))

    return ("%s-%s-%s %s"):format(day, month_name, year, weekday)
end

---@param task table
---@return string
local function task_description(task)
    if type(task.description) == "string" and task.description ~= "" then
        return task.description
    end

    if type(task.task) == "string" and task.task ~= "" then
        return task.task
    end

    return "Untitled task"
end

---@param tasks table[]
---@param week_lookup table<string, boolean>
---@return table<string, TaskMDCalendarWeekTask[]>
local function week_tasks(tasks, week_lookup)
    local grouped = {}

    for _, task in ipairs(tasks) do
        if type(task) == "table" then
            local due = task_date(task.due)

            if due and week_lookup[due] then
                local time, minutes = task_time(task.due)

                grouped[due] = grouped[due] or {}

                table.insert(grouped[due], {
                    key = due,
                    kind = "Due",
                    group = "TaskMDCalendarDue",
                    description = task_description(task),
                    time = time,
                    minutes = minutes,
                })
            end

            local scheduled = task_date(task.scheduled)

            if scheduled and week_lookup[scheduled] then
                local time, minutes = task_time(task.scheduled)

                grouped[scheduled] = grouped[scheduled] or {}

                table.insert(grouped[scheduled], {
                    key = scheduled,
                    kind = "Scheduled",
                    group = "TaskMDCalendarScheduled",
                    description = task_description(task),
                    time = time,
                    minutes = minutes,
                })
            end
        end
    end

    for _, items in pairs(grouped) do
        table.sort(items, function(left, right)
            if left.minutes == right.minutes then
                return left.description < right.description
            end

            return left.minutes < right.minutes
        end)
    end

    return grouped
end

---@param highlights TaskMDCalendarHighlight[]
---@param row integer
---@param start_col integer
---@param end_col integer
---@param group string
local function add_highlight(highlights, row, start_col, end_col, group)
    if end_col <= start_col then
        return
    end

    table.insert(highlights, {
        row = row,
        start_col = start_col,
        end_col = end_col,
        group = group,
    })
end

---@param lines string[]
---@param highlights TaskMDCalendarHighlight[]
---@param text string
---@param group string?
local function append_line(lines, highlights, text, group)
    table.insert(lines, text)

    if group then
        add_highlight(highlights, #lines - 1, 0, #text, group)
    end
end

---@param lines string[]
---@param highlights TaskMDCalendarHighlight[]
---@param key string
local function append_week_date(lines, highlights, key)
    local text = "- " .. display_week_date(key)

    table.insert(lines, text)
    add_highlight(highlights, #lines - 1, 2, #text, "TaskMDCalendarWeekDate")
end

---@param lines string[]
---@param highlights TaskMDCalendarHighlight[]
---@param item TaskMDCalendarWeekTask
local function append_week_task(lines, highlights, item)
    local time = ""

    if item.time then
        time = " " .. item.time
    end

    local text = ("    - %s: %s%s"):format(item.kind, item.description, time)

    table.insert(lines, text)

    local row = #lines - 1
    local kind_start = 6
    local kind_end = kind_start + #item.kind
    local task_start = kind_end + 2
    local task_end = #text

    add_highlight(highlights, row, kind_start, kind_end + 1, item.group)

    if item.time then
        local time_start = text:find(item.time, 1, true)

        if time_start then
            task_end = time_start - 2

            add_highlight(
                highlights,
                row,
                time_start - 1,
                time_start + #item.time - 1,
                "TaskMDCalendarWeekTime"
            )
        end
    end

    add_highlight(highlights, row, task_start, task_end, "TaskMDCalendarWeekTask")
end

---@param tasks table[]
---@return string[], TaskMDCalendarHighlight[]
local function render_week(tasks)
    local lines = {}
    local highlights = {}
    local week_keys, week_lookup = current_week()
    local grouped = week_tasks(tasks, week_lookup)
    local has_task = false

    append_line(lines, highlights, "", nil)
    append_line(lines, highlights, "This week:", "TaskMDCalendarThisWeek")

    for _, key in ipairs(week_keys) do
        local items = grouped[key]

        if items and #items > 0 then
            has_task = true

            append_week_date(lines, highlights, key)

            for _, item in ipairs(items) do
                append_week_task(lines, highlights, item)
            end
        end
    end

    if not has_task then
        append_line(
            lines,
            highlights,
            "- No pending due or scheduled tasks.",
            "TaskMDCalendarWeekTask"
        )
    end

    return lines, highlights
end

---@param lines string[]
---@param highlights TaskMDCalendarHighlight[]
---@param extra_lines string[]
---@param extra_highlights TaskMDCalendarHighlight[]
local function append_lines(lines, highlights, extra_lines, extra_highlights)
    local row_offset = #lines

    for _, line in ipairs(extra_lines) do
        table.insert(lines, line)
    end

    for _, highlight in ipairs(extra_highlights) do
        table.insert(highlights, {
            row = highlight.row + row_offset,
            start_col = highlight.start_col,
            end_col = highlight.end_col,
            group = highlight.group,
        })
    end
end

---@param lines string[]
---@param highlights TaskMDCalendarHighlight[]
local function add_horizontal_padding(lines, highlights)
    local padding = string.rep(" ", horizontal_padding)

    for i, line in ipairs(lines) do
        lines[i] = padding .. line .. padding
    end

    for _, highlight in ipairs(highlights) do
        highlight.start_col = highlight.start_col + horizontal_padding
        highlight.end_col = highlight.end_col + horizontal_padding
    end
end

---@param lines string[]
---@return integer
local function max_width(lines)
    local longest = 1

    for _, line in ipairs(lines) do
        longest = math.max(longest, #line)
    end

    return longest
end

---@return table[]
local function pending_tasks()
    local tasks = taskwarrior.pending()

    if type(tasks) ~= "table" then
        return {}
    end

    return tasks
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

    local tasks = pending_tasks()
    local marks = task_marks(tasks)
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
    local week_lines, week_highlights = render_week(tasks)

    append_lines(lines, joined_highlights, week_lines, week_highlights)
    add_horizontal_padding(lines, joined_highlights)

    local bufnr = vim.api.nvim_create_buf(false, true)

    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "taskmd-calendar"

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false

    local ui = vim.api.nvim_list_uis()[1]
    local win_width = max_width(lines)
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
        border = border(),
    })

    vim.wo[winid].winhighlight =
        "NormalFloat:TaskMDCalendarFloat,FloatBorder:TaskMDCalendarBorder"

    vim.wo[winid].wrap = false
    vim.wo[winid].cursorline = false
    vim.wo[winid].signcolumn = "no"
    vim.wo[winid].number = false
    vim.wo[winid].relativenumber = false

    set_keymaps(bufnr)
    apply_highlights(bufnr, joined_highlights)
end

return M
