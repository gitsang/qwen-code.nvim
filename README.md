# gemini-cli.nvim

🤖 Seamlessly integrate GeminiCLI with Neovim for an enhanced AI-assisted coding experience!

## 🌟 Features

- [x] 🖥️ Gemini CLI terminal integration within Neovim
- [x] 📤 Quick commands to add current buffer files (using `@` syntax)
- [x] 🩺 Send current buffer diagnostics to Gemini CLI
- [x] 🔍 Gemini CLI command selection UI with fuzzy search and input prompt
- [x] 🔌 Fully documented [Lua API](lua/gemini_cli/api.lua) for
      programmatic interaction and custom integrations
- [x] 🔄 Auto-reload buffers on external changes (requires 'autoread')

## 🎮 Commands

- `:Gemini` - Open interactive command menu

  ```text
  Commands:
  health         🩺 Check plugin health status
  toggle         🎛️ Toggle GeminiCLI terminal window
  command        ⌨️ Show slash commands
   > diagnostics 🩺 Send current buffer diagnostics
  add_file       ➕ Add current file to session (using `@` syntax)
  ask            ❓ Ask a question
  ```

- ⚡ Direct command execution examples:

  ```vim
  :Gemini health
  :Gemini add_file
  :Gemini send "Fix login validation"
  ```

## 🔗 Requirements

🐍 Python: Install `gemini-cli`
📋 System: **Neovim** >= 0.9.4
🌙 Lua: `folke/snacks.nvim`,

## 📦 Installation

Using lazy.nvim:

```lua
{
    "marcinjahn/gemini-cli.nvim",
    cmd = "Gemini",
    -- Example key mappings for common actions:
    keys = {
      { "<leader>a/", "<cmd>Gemini toggle<cr>", desc = "Toggle Gemini CLI" },
      { "<leader>aa", "<cmd>Gemini ask<cr>", desc = "Ask Gemini", mode = { "n", "v" } },
      { "<leader>af", "<cmd>Gemini add_file<cr>", desc = "Add File" },

    },
    dependencies = {
      "folke/snacks.nvim",
    },
    config = true,
  }
```

After installing, run `:GeminiCLI health` to check if everything is set up correctly.

## ⚙️ Configuration

There is no need to call setup if you don't want to change the default options.

```lua
require("gemini_cli").setup({
  -- Command that executes GeminiCLI
  gemini_cmd = "gemini",
  -- Command line arguments passed to gemini-cli
  args = {
  },
  -- Automatically reload buffers changed by GeminiCLI (requires vim.o.autoread = true)
  auto_reload = false,
  -- snacks.picker.layout.Config configuration
  picker_cfg = {
    preset = "vscode",
  },
  -- Other snacks.terminal.Opts options
  config = {
    os = { editPreset = "nvim-remote" },
    gui = { nerdFontsVersion = "3" },
  },
  win = {
    wo = { winbar = "GeminiCLI" },
    style = "gemini_cli",
    position = "right",
  },
})
```

## 📚 API Reference

The plugin provides a structured API for programmatic integration. Access via `require("gemini_cli").api`

### Core Functions

```lua
local api = require("gemini_cli").api
```

#### `health_check()`

Verify plugin health status

```lua
api.health_check()
```

#### `toggle_terminal(opts?)`

Toggle GeminiCLI terminal window

```lua
api.toggle_terminal()
```

---

### Terminal Operations

#### `send_to_terminal(text, opts?)`

Send raw text directly to GeminiCLI

```lua
api.send_to_terminal("Fix the login validation")
```

#### `send_command(command, input?, opts?)`

Execute specific GeminiCLI command

```lua
api.send_command("/commit", "Add error handling")
```

### File Management

#### `add_file(filepath)`

Add specific file to session

```lua
api.add_file("/src/utils.lua")
```

``

#### `add_current_file()`

Add current buffer's file (uses `add_file` internally)

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    api.add_current_file()
  end
})
```

#### `send_diagnostics_with_prompt(opts?)`

Send current buffer's diagnostics with an optional prompt

```lua
api.send_diagnostics_with_prompt()
```

---

### UI Components

#### `open_command_picker(opts?, callback?)`

Interactive command selector with custom handling

```lua
api.open_command_picker(nil, function(picker, item)
  if item.text == "/custom" then
    -- Implement custom command handling
  else
    -- Default behavior
    picker:close()
    api.send_command(item.text)
  end
end)
```

---

This plugin is a Gemini CLI adaptation of [nvim-aider](https://github.com/GeorgesAlkhouri/nvim-aider).
