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

    local hours = math.floor(diff / 3600)
    local mins = math.floor((diff % 3600) / 60)

    if hours > 0 and mins > 0 then
        return ("%dh %dm"):format(hours, mins)
    end

    if hours > 0 then
        return ("%dh"):format(hours)
    end

    return ("%dm"):format(mins)
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

return M
