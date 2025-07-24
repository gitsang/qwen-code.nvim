vim.api.nvim_create_user_command("Qwen", function(opts)
  local commands_menu = require("gemini_cli.commands_menu")

  if #opts.fargs == 0 then
    commands_menu._menu()
  else
    commands_menu._load_command(opts.fargs)
  end
end, {
  desc = "Aider command interface",
  nargs = "*",
  complete = function(arg_lead, line)
    local cmds = require("gemini_cli.commands_menu").commands
    local parts = vim.split(line:gsub("%s+", " "), " ")

    -- Complete subcommands when typing after main command
    if #parts >= 2 then
      local main_cmd = parts[2]
      if cmds[main_cmd] and cmds[main_cmd].subcommands then
        return vim
          .iter(vim.tbl_keys(cmds[main_cmd].subcommands))
          :filter(function(key)
            return key:find(arg_lead) == 1
          end)
          :totable()
      end
    end

    -- Complete main commands
    return vim
      .iter(vim.tbl_keys(cmds))
      :filter(function(key)
        return key:find(arg_lead) == 1
      end)
      :totable()
  end,
})

-- Track which deprecation warnings have been shown
local deprecated_shown = {}

-- Create a wrapper function for deprecated commands
local function create_deprecated_handler(cmd, replacement, handler)
  return function(opts)
    if not deprecated_shown[cmd] then
      vim.notify(
        ("`%s` is deprecated and will be removed in future versions - use `%s` instead"):format(cmd, replacement),
        vim.log.levels.WARN,
        { title = "gemini-cli" }
      )
      deprecated_shown[cmd] = true
    end
    handler(opts)
  end
end

vim.api.nvim_create_user_command(
  "QwenHealth",
  create_deprecated_handler("QwenHealth", "Qwen health", function()
    require("gemini_cli.api").health_check()
  end),
  { desc = "Run gemini-cli health check" }
)

vim.api.nvim_create_user_command(
  "QwenTerminalToggle",
  create_deprecated_handler("QwenTerminalToggle", "Qwen toggle", function()
    require("gemini_cli.api").toggle_terminal()
  end),
  { desc = "Toggle Qwen terminal" }
)

vim.api.nvim_create_user_command(
  "QwenTerminalSend",
  create_deprecated_handler("QwenTerminalSend", "Qwen send", function(args)
    require("gemini_cli.api").send_to_terminal(args.args)
  end),
  { nargs = "?", range = true, desc = "Send text to Qwen terminal" }
)

vim.api.nvim_create_user_command(
  "QwenQuickSendCommand",
  create_deprecated_handler("QwenQuickSendCommand", "Qwen command", function()
    require("gemini_cli.api").open_command_picker()
  end),
  { desc = "Send Qwen slash command to Qwen terminal" }
)

vim.api.nvim_create_user_command(
  "QwenQuickSendBuffer",
  create_deprecated_handler("QwenQuickSendBuffer", "Qwen buffer", function()
    require("gemini_cli.api").send_buffer_with_prompt()
  end),
  { desc = "Send buffer to Qwen terminal" }
)

vim.api.nvim_create_user_command(
  "QwenQuickAddFile",
  create_deprecated_handler("QwenQuickAddFile", "Qwen add", function()
    require("gemini_cli.api").add_current_file()
  end),
  { desc = "Add current file to Qwen session" }
)

vim.api.nvim_create_user_command(
  "QwenQuickReadOnlyFile",
  create_deprecated_handler("QwenQuickReadOnlyFile", "Qwen add readonly", function()
    require("gemini_cli.api").add_read_only_file()
  end),
  { desc = "Add current file as read-only to Qwen session" }
)
