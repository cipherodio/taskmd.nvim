---
title: TaskMD
author: Jeremy
description: Markdown + Taskwarrior integration for Neovim.
---

## Features

- Add Taskwarrior tasks from Neovim
- Fetch pending Taskwarrior tasks into Markdown
- Sync Markdown task lines from Taskwarrior
- Delete Taskwarrior tasks from Markdown
- Support recurring Taskwarrior tasks
- Optionally sync configured files once when opened

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
    sync_on_open = true,

    file_path = {
        "~/hub/src/mdnotes/agenda.md",
        "~/hub/src/mdnotes/todo.md",
    },

    short_uuid = true,

    keymaps = {
        add = "<leader>ta",
        sync = "<leader>ts",
        delete = "<leader>td",
        fetch = "<leader>tf",
    },
})
```

## Commands

```vim
:TaskMD add
:TaskMD sync
:TaskMD delete
:TaskMD fetch
```

## Example

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
Task: Prime Video Subscription
Date:
Scheduled:
Due: 7th
Recur: monthly
Project: bills
Priority: H
Tags:
```

Example Markdown output:

```md
- Prime Video Subscription due:july-07-2026 @12:00am in:6d recur:monthly uuid:8a6d2134
```

## Sync on open

When `sync_on_open` is enabled, TaskMD silently syncs configured files
once when they are opened.

```lua
sync_on_open = true

file_path = {
    "~/hub/src/mdnotes/agenda.md",
    "~/hub/src/mdnotes/todo.md",
}
```

To sync manually:

```vim
:TaskMD sync
```

## Recurring tasks

Taskwarrior recurring tasks create two records:

```text
R = recurring parent/template
P = pending child/current task
```

TaskMD stores the UUID of the pending child task.

This is normal Taskwarrior behavior. Use:

```sh
task
```

to see normal pending tasks, and:

```sh
task all
```

to see everything, including recurring parents/templates.

## Healthcheck

```vim
:checkhealth taskmd
```

## Help

```vim
:help taskmd
```
