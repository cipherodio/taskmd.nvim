local M = {}

local months = {
    "january",
    "february",
    "march",
    "april",
    "may",
    "june",
    "july",
    "august",
    "september",
    "october",
    "november",
    "december",
}

---@param date string
---@return string?
function M.display_date(date)
    local year, month, day = date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")

    if not (year and month and day) then
        return nil
    end

    local month_name = months[tonumber(month)]

    if not month_name then
        return nil
    end

    return ("%s-%s-%s"):format(month_name, day, year)
end

---@param time string
---@return string
function M.display_time(time)
    return (time:lower():gsub("%s+", ""))
end

---@param time string
---@return integer?
local function time_to_24h(time)
    local hour, min, meridiem = time:lower():match("^(%d%d?):(%d%d)([ap]m)$")

    if not (hour and min and meridiem) then
        return nil
    end

    local h = tonumber(hour)
    local m = tonumber(min)

    if not (h and m) then
        return nil
    end

    if meridiem == "pm" and h ~= 12 then
        h = h + 12
    end

    if meridiem == "am" and h == 12 then
        h = 0
    end

    return h * 60 + m
end

---@param seconds integer
---@return string
local function format_duration(seconds)
    local minute = 60
    local hour = minute * 60
    local day = hour * 24
    local week = day * 7
    local month = day * 30
    local year = day * 365

    local years = math.floor(seconds / year)
    seconds = seconds % year

    local month_count = math.floor(seconds / month)
    seconds = seconds % month

    if years == 0 and month_count >= 12 then
        years = 1
        month_count = month_count - 12
    end

    local weeks = math.floor(seconds / week)
    seconds = seconds % week

    local days = math.floor(seconds / day)
    seconds = seconds % day

    local hours = math.floor(seconds / hour)
    seconds = seconds % hour

    local minutes = math.floor(seconds / minute)

    local parts = {}

    if years > 0 then
        table.insert(parts, ("%dy"):format(years))
    end

    if month_count > 0 then
        table.insert(parts, ("%dmo"):format(month_count))
    end

    if weeks > 0 then
        table.insert(parts, ("%dw"):format(weeks))
    end

    if days > 0 then
        table.insert(parts, ("%dd"):format(days))
    end

    if hours > 0 then
        table.insert(parts, ("%dh"):format(hours))
    end

    if minutes > 0 then
        table.insert(parts, ("%dm"):format(minutes))
    end

    if #parts == 0 then
        return "0m"
    end

    return table.concat(parts, " ")
end

---@param date string
---@param time string
---@return string?
function M.time_left(date, time)
    local year, month, day = date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")

    if not (year and month and day) then
        return nil
    end

    local minutes = time_to_24h(M.display_time(time))

    if not minutes then
        return nil
    end

    local y = tonumber(year)
    local m = tonumber(month)
    local d = tonumber(day)

    if not (y and m and d) then
        return nil
    end

    local target = os.time({
        year = y,
        month = m,
        day = d,
        hour = math.floor(minutes / 60),
        min = minutes % 60,
        sec = 0,
    })

    if not target then
        return nil
    end

    local diff = target - os.time()

    if diff <= 0 then
        return "overdue"
    end

    return format_duration(diff)
end

---@param date string
---@param time string
---@return string?
function M.task_datetime(date, time)
    local year, month, day = date:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")

    if not (year and month and day) then
        return nil
    end

    local minutes = time_to_24h(M.display_time(time))

    if not minutes then
        return nil
    end

    local y = tonumber(year)
    local m = tonumber(month)
    local d = tonumber(day)

    if not (y and m and d) then
        return nil
    end

    local hour = math.floor(minutes / 60)
    local min = minutes % 60

    return ("%04d-%02d-%02dT%02d:%02d"):format(y, m, d, hour, min)
end

local month_numbers = {
    january = "01",
    february = "02",
    march = "03",
    april = "04",
    may = "05",
    june = "06",
    july = "07",
    august = "08",
    september = "09",
    october = "10",
    november = "11",
    december = "12",
}

---@param display_date string
---@return string?
function M.parse_display_date(display_date)
    local month, day, year = display_date:match("^([a-z]+)%-(%d%d)%-(%d%d%d%d)$")

    if not (month and day and year) then
        return nil
    end

    local month_number = month_numbers[month]

    if not month_number then
        return nil
    end

    return ("%s-%s-%s"):format(year, month_number, day)
end

---@param hour integer
---@param min integer
---@return string
local function display_12h(hour, min)
    local meridiem = "am"

    if hour >= 12 then
        meridiem = "pm"
    end

    local display_hour = hour % 12

    if display_hour == 0 then
        display_hour = 12
    end

    return ("%02d:%02d%s"):format(display_hour, min, meridiem)
end

---@param t osdateparam
---@return integer?
local function utc_to_epoch(t)
    local local_epoch = os.time(t)

    if not local_epoch then
        return nil
    end

    local local_date = os.date("*t", local_epoch)
    local utc_date = os.date("!*t", local_epoch)

    if type(local_date) ~= "table" or type(utc_date) ~= "table" then
        return nil
    end

    local offset = os.difftime(os.time(local_date), os.time(utc_date))

    return local_epoch + offset
end

---@param value string
---@return string?, string?
function M.from_taskwarrior_datetime(value)
    local year, month, day, hour, min, sec =
        value:match("^(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)Z$")

    if year then
        local y = tonumber(year)
        local m = tonumber(month)
        local d = tonumber(day)
        local h = tonumber(hour)
        local mi = tonumber(min)
        local s = tonumber(sec)

        if not (y and m and d and h and mi and s) then
            return nil, nil
        end

        local epoch = utc_to_epoch({
            year = y,
            month = m,
            day = d,
            hour = h,
            min = mi,
            sec = s,
        })

        if not epoch then
            return nil, nil
        end

        local local_time = os.date("*t", epoch)

        if type(local_time) ~= "table" then
            return nil, nil
        end

        local local_year = tonumber(local_time.year)
        local local_month = tonumber(local_time.month)
        local local_day = tonumber(local_time.day)
        local local_hour = tonumber(local_time.hour)
        local local_min = tonumber(local_time.min)

        if
            not (local_year and local_month and local_day and local_hour and local_min)
        then
            return nil, nil
        end

        return ("%04d-%02d-%02d"):format(local_year, local_month, local_day),
            display_12h(local_hour, local_min)
    end

    year, month, day, hour, min = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d)")

    if not (year and month and day and hour and min) then
        return nil, nil
    end

    local h = tonumber(hour)
    local mi = tonumber(min)

    if not (h and mi) then
        return nil, nil
    end

    return ("%s-%s-%s"):format(year, month, day), display_12h(h, mi)
end

return M
