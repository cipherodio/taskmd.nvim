---
title: TaskMD
author: Jeremy
description: Markdown + Taskwarrior integration for Neovim.
---

## Features

- Add Taskwarrior tasks from Neovim
- Fetch pending Taskwarrior tasks into Markdown
- Sync Markdown task lines from Taskwarrior
- Mark tasks as done from Markdown
- Delete Taskwarrior tasks from Markdown
- Support recurring Taskwarrior tasks
- Show a Taskwarrior calendar inside Neovim
- Show current-week due and scheduled tasks in the calendar
- Optionally sync TaskMD files once when opened
- Optional highlighting for TaskMD task metadata

## Requirements

- Neovim 0.12+
- Taskwarrior

The `task` command must be available in your `PATH`.

## Installation

Example using `vim.pack`:

```lua
vim.pack.add({
    { src = "https://github.com/cipherodio/taskmd.nvim" },
}, { confirm = false })
```

## Setup

```lua
require("taskmd").setup({
    -- Root directory where TaskMD is active.
    root_dir = "~/hub/src/mdnotes"

    -- Optional directory or list of directories scanned by fetch
    -- to avoid duplicate tasks.
    scan_dir = "events",

    -- Default task file used when running commands outside root_dir.
    task_file = "agenda.md",

    -- Sync TaskMD files once when opened.
    sync_on_open = {
        enable = true,
        autowrite = true,
    },

    -- Write the buffer after commands that modify Markdown.
    write_on_command = true,

    -- Show short task IDs in Markdown.
    short_uuid = true,

    highlight = {
        file_output = {
            enable = true,
            -- Optional color overrides for Markdown task metadata.
            -- Use "#RRGGBB" hex colors or Neovim color names.
            -- Leave unset, set to nil, or use "" to use the default colors.
            overrides = {
                scheduled = "",
                due = "",
                duration = "",
                rec = "",
                rec_value = "",
                id = "",
            },
        },
        -- Floating calendar
        calendar = {
            -- Values: "none", "single", "double", "rounded", "solid", "shadow"
            border = "single",
            -- Optional color overrides for the calendar.
            -- Use "#RRGGBB" hex colors or Neovim color names.
            -- Leave unset, set to nil, or use "" to use the default colors.
            overrides = {
                -- Calendar
                month = "",
                weekday = "",
                day = "",
                today = "",
                due = "",
                scheduled = "",
                sched_due = "",
                -- Current-week task list
                this_week = "",
                week_date = "",
                week_task = "",
                week_time = "",
            },
        },
    },

    keymaps = {
        add = "<leader>ta", -- :TaskMD add
        sync = "<leader>ts", -- :TaskMD sync
        delete = "<leader>tx", -- :TaskMD delete
        done = "<leader>td", -- TaskMD done
        fetch = "<leader>tf", -- TaskMD fetch
        calendar = "<leader>tc", -- TaskMD calendar
    },
})
```

## Command behavior

```text
:TaskMD add
    inside root_dir  -> insert at cursor in current file
    outside root_dir -> append to task_file

:TaskMD sync
    inside root_dir  -> sync current file
    outside root_dir -> sync task_file

:TaskMD fetch
    inside root_dir  -> insert missing tasks at cursor in current file
    outside root_dir -> append missing tasks to task_file

:TaskMD done
    mark the task on the current line as done, then remove the line

:TaskMD delete
    delete the task on the current line, then remove the line

:TaskMD calendar
    open the TaskMD calendar
```

## Adding a task

Running:

```vim
:TaskMD add
```

asks for:

```text
Task:
Date:
Scheduled:
Due:
Recur:
Project:
Priority:
Tags:
```

Example input:

```text
Task: Pay bills
Date: 2026-07-07
Scheduled:
Due: 05:30pm
Recur: monthly
Project: bills
Priority: H
Tags:
```

Example Markdown output:

```md
- Pay bills due:4d 12h rec:m id:8a6d2134
```

The duration depends on the current time when the task is rendered.

## Highlight groups

Markdown task output:

```text
TaskMDScheduled
TaskMDDue
TaskMDDuration
TaskMDRecur
TaskMDRecurValue
TaskMDId
```

Calendar:

```text
TaskMDCalendarMonth
TaskMDCalendarWeekday
TaskMDCalendarDay
TaskMDCalendarToday
TaskMDCalendarDue
TaskMDCalendarScheduled
TaskMDCalendarBoth
TaskMDCalendarThisWeek
TaskMDCalendarWeekDate
TaskMDCalendarWeekTask
TaskMDCalendarWeekTime
```

## Healthcheck

```vim
:checkhealth taskmd
```

## Help

```vim
:help taskmd
```
