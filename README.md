---
title: TaskMD
author: Jeremy
description: Neovim plugin for creating task for Taskwarrior
---

Markdown + Taskwarrior integration for Neovim.

## Features

- Add Taskwarrior tasks from Neovim
- Insert tasks into Markdown
- Sync Markdown task lines from Taskwarrior
- Refresh `in:` time using the stored task UUID

## Requirements

- Neovim 0.12+
- Taskwarrior

## Installation

Example using `vim.pack`:

```lua
vim.pack.add({
    { src = "https://github.com/cipherodio/taskmd.nvim" },
})
```

## Setup

```lua
require("taskmd").setup({
    keymaps = {
        add = "<leader>ta",
        sync = "<leader>ts",
    },
})
```

## Commands

```vim
:TaskMD add
:TaskMD sync
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
Project:
Priority:
Tags:
```

Example Markdown output:

```md
- Cook meal scheduled:june-29-2026 @11:55pm in:6m uuid:9b2f859a-9428-437b-84c1-d0857e5731d2
```

Due tasks use this format:

```md
- Cook meal due:june-29-2026 @11:55pm in:6m uuid:9b2f859a-9428-437b-84c1-d0857e5731d2
```

## Health

```vim
:checkhealth taskmd
```

## License

MIT
