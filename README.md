# gemini-cli.nvim

🤖 Seamlessly integrate GeminiCLI with Neovim for an enhanced AI-assisted coding experience!

## 1. 🌟 Features

- [x] 🖥️ Gemini CLI terminal integration within Neovim
- [x] 📤 Quick commands to add current buffer files (using `@` syntax)
- [x] 🩺 Send current buffer diagnostics to Gemini CLI
- [x] 🔍 Gemini CLI command selection UI with fuzzy search and input prompt
- [x] 🔌 Fully documented [Lua API](lua/gemini_cli/api.lua) for
      programmatic interaction and custom integrations
- [x] 🔄 Auto-reload buffers on external changes (requires 'autoread')

## 2. 🎮 Commands

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

## 3. 🔗 Requirements

🐍 Python: Install `gemini-cli`
📋 System: **Neovim** >= 0.9.4
🌙 Lua: `folke/snacks.nvim`,

## 4. 📦 Installation

Using lazy.nvim:

```lua
{
    "gitsang/qwen-code.nvim",
    cmd = "Qwen",
    -- Example key mappings for common actions:
    keys = {
      { "<leader>qq", "<cmd>Qwen toggle<cr>", desc = "Toggle Qwen CLI" },
      { "<leader>qa", "<cmd>Qwen ask<cr>", desc = "Ask Qwen", mode = { "n", "v" } },
      { "<leader>qf", "<cmd>Qwen add_file<cr>", desc = "Add File" },

    },
    dependencies = {
      "folke/snacks.nvim",
    },
    config = true,
  }
```

After installing, run `:GeminiCLI health` to check if everything is set up correctly.

## 5. ⚙️ Configuration

There is no need to call setup if you don't want to change the default options.

```lua
require("gemini_cli").setup({
  -- Command that executes GeminiCLI
  gemini_cmd = "qwen",
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
    wo = { winbar = "QwenCode" },
    style = "gemini_cli",
    position = "right",
  },
})
```

## 6. 📚 API Reference

The plugin provides a structured API for programmatic integration. Access via `require("gemini_cli").api`

### 6.1 Core Functions

```lua
local api = require("gemini_cli").api
```

#### 6.1.1 `health_check()`

Verify plugin health status

```lua
api.health_check()
```

#### 6.1.2 `toggle_terminal(opts?)`

Toggle GeminiCLI terminal window

```lua
api.toggle_terminal()
```

---

### 6.2 Terminal Operations

#### 6.2.1 `send_to_terminal(text, opts?)`

Send raw text directly to GeminiCLI

```lua
api.send_to_terminal("Fix the login validation")
```

#### 6.2.2 `send_command(command, input?, opts?)`

Execute specific GeminiCLI command

```lua
api.send_command("/commit", "Add error handling")
```

### 6.3 File Management

#### 6.3.1 `add_file(filepath)`

Add specific file to session

```lua
api.add_file("/src/utils.lua")
```

``

#### 6.3.2 `add_current_file()`

Add current buffer's file (uses `add_file` internally)

```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    api.add_current_file()
  end
})
```

#### 6.3.3 `send_diagnostics_with_prompt(opts?)`

Send current buffer's diagnostics with an optional prompt

```lua
api.send_diagnostics_with_prompt()
```

---

### 6.4 UI Components

#### 6.4.1 `open_command_picker(opts?, callback?)`

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
