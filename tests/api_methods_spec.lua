local mock = require("luassert.mock")
local spy = require("luassert.spy")
local stub = require("luassert.stub")

describe("API Methods", function()
  local terminal_mock
  local picker_mock
  local utils_mock
  local input_stub
  local nvim_aider
  local bufname_stub

  before_each(function()
    package.loaded["nvim_aider.health"] = {
      check = stub.new(),
    }

    -- Now require the module
    package.loaded["nvim_aider"] = nil
    nvim_aider = require("nvim_aider")
    nvim_aider.setup()

    -- Then mock other components
    terminal_mock = mock(require("nvim_aider.terminal"), true)
    picker_mock = mock(require("nvim_aider.picker"), true)
    utils_mock = mock(require("nvim_aider.utils"), true)
    input_stub = stub(vim.ui, "input")
    bufname_stub = stub(vim.fn, "bufname")
  end)

  after_each(function()
    -- Clean up modules
    package.loaded["nvim_aider"] = nil
    package.loaded["nvim_aider.health"] = nil
    package.loaded["nvim_aider.config"] = nil

    -- Clean up mocks
    mock.revert(terminal_mock)
    mock.revert(picker_mock)
    mock.revert(utils_mock)
    input_stub:revert()
    bufname_stub:revert()
  end)
  --
  describe("Core Functionality", function()
    it("health_check executes without errors", function()
      nvim_aider.api.health_check()
      assert.stub(require("nvim_aider.health").check).was_called()
    end)

    it("toggle_terminal calls terminal.toggle", function()
      nvim_aider.api.toggle_terminal({ size = 20 })
      assert.stub(terminal_mock.toggle).was_called_with({ size = 20 })
    end)
  end)

  describe("Terminal Interactions", function()
    it("send_to_terminal passes text to terminal", function()
      nvim_aider.api.send_to_terminal("test content", { echo = false })
      assert.stub(terminal_mock.send).was_called_with("test content", { echo = false })
    end)

    it("send_command executes terminal command", function()
      nvim_aider.api.send_command("/test", "input", { silent = true })
      assert.stub(terminal_mock.command).was_called_with("/test", "input", { silent = true })
    end)

    it("reset_session executes terminal command", function()
      nvim_aider.api.reset_session({ force = true })
      assert.stub(terminal_mock.command).was_called_with("/reset", nil, { force = true })
    end)
  end)

  describe("File Operations", function()
    it("add_file with valid path", function()
      nvim_aider.api.add_file("/test/path", { force = true })
      assert.stub(terminal_mock.command).was_called_with("/add", "/test/path", { force = true })
    end)

    it("add_file without path shows error", function()
      local notify_spy = spy.on(vim, "notify")
      nvim_aider.api.add_file(nil)
      assert.stub(terminal_mock.command).was_not_called()
      assert.spy(notify_spy).was_called_with("No file path provided", vim.log.levels.ERROR)
    end)

    it("drop_file with valid path", function()
      nvim_aider.api.drop_file("/test/path", { confirm = false })
      assert.stub(terminal_mock.command).was_called_with("/drop", "/test/path", { confirm = false })
    end)

    it("drop_file without path shows error", function()
      local notify_spy = spy.on(vim, "notify")
      nvim_aider.api.drop_file(nil)
      assert.stub(terminal_mock.command).was_not_called()
      assert.spy(notify_spy).was_called_with("No file path provided", vim.log.levels.ERROR)
    end)
  end)

  describe("Buffer Operations", function()
    before_each(function()
      -- Create a new modifiable buffer for each test
      local buf = vim.api.nvim_create_buf(true, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].modifiable = true

      utils_mock.get_absolute_path.returns("/project/file.lua")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "line1", "line2" })
    end)

    it("send_buffer_with_prompt with input", function()
      input_stub.invokes(function(_, cb)
        cb("user prompt")
      end)
      nvim_aider.api.send_buffer_with_prompt()
      assert.stub(terminal_mock.send).was_called_with("line1\nline2\n> user prompt", {}, true)
    end)

    it("send_buffer_with_prompt without input", function()
      input_stub.invokes(function(_, cb)
        cb("")
      end)
      nvim_aider.api.send_buffer_with_prompt()
      assert.stub(terminal_mock.send).was_called_with("line1\nline2", {}, true)
    end)

    it("add_current_file with valid buffer", function()
      nvim_aider.api.add_current_file({ force = true })
      assert.stub(terminal_mock.command).was_called_with("/add", "/project/file.lua", { force = true })
    end)

    it("drop_current_file with valid buffer", function()
      nvim_aider.api.drop_current_file({ confirm = false })
      assert.stub(terminal_mock.command).was_called_with("/drop", "/project/file.lua", { confirm = false })
    end)

    it("add_read_only_file with valid buffer", function()
      nvim_aider.api.add_read_only_file()
      assert.stub(terminal_mock.command).was_called_with("/read-only", "/project/file.lua", nil)
    end)

    it("send_diagnostics_with_prompt without input", function()
      -- Mock diagnostics
      local mock_diagnostics = {
        {
          bufnr = 0,
          lnum = 0,
          col = 0,
          severity = vim.diagnostic.severity.ERROR,
          message = "Error message 1",
          source = "linter1",
        },
        {
          bufnr = 0,
          lnum = 1,
          col = 5,
          severity = vim.diagnostic.severity.WARN,
          message = "Warning message 2",
          source = "linter2",
        },
      }
      local get_diagnostic_stub = stub(vim.diagnostic, "get")
      get_diagnostic_stub.returns(mock_diagnostics)
      bufname_stub.returns("test_buffer.lua") -- Mock buffer name

      -- Calculate the expected output from the actual formatter
      local expected_formatted_output = "ERROR|L1:C1|linter1||Error message 1\n"
        .. "WARN|L2:C6|linter2||Warning message 2"

      input_stub.invokes(function(opts, cb)
        -- Assert the prompt and default values passed to vim.ui.input
        assert.are.equal("Add a prompt for the diagnostics:", opts.prompt)
        assert.are.equal("Here are the diagnostics for test_buffer.lua:", opts.default)
        cb("") -- Simulate user pressing enter without input
      end)
      nvim_aider.api.send_diagnostics_with_prompt()

      -- Expected output should be just the formatted diagnostics when input is empty
      assert.stub(terminal_mock.send).was_called_with(expected_formatted_output, {}, true)

      -- Clean up stub
      get_diagnostic_stub:revert()
    end)

    it("send_diagnostics_with_prompt with input", function()
      -- Mock diagnostics
      local mock_diagnostics = {
        {
          bufnr = 0,
          lnum = 0,
          col = 0,
          severity = vim.diagnostic.severity.ERROR,
          message = "Error message 1",
          source = "linter1",
        },
      }
      local get_diagnostic_stub = stub(vim.diagnostic, "get")
      get_diagnostic_stub.returns(mock_diagnostics)
      bufname_stub.returns("test_buffer.lua") -- Mock buffer name

      -- Calculate the expected output from the actual formatter
      local expected_formatted_output = "ERROR|L1:C1|linter1||Error message 1"

      local user_input = "user prompt"
      input_stub.invokes(function(opts, cb)
        -- Assert the prompt and default values passed to vim.ui.input
        assert.are.equal("Add a prompt for the diagnostics:", opts.prompt)
        assert.are.equal("Here are the diagnostics for test_buffer.lua:", opts.default)
        cb(user_input) -- Simulate user providing input
      end)
      nvim_aider.api.send_diagnostics_with_prompt()

      -- Expected output should be user input + newline + formatted diagnostics
      local expected_output = user_input .. "\n" .. expected_formatted_output

      assert.stub(terminal_mock.send).was_called_with(expected_output, {}, true)

      -- Clean up stub
      get_diagnostic_stub:revert()
    end)
  end)

  describe("Command Picker", function()
    it("opens picker with commands", function()
      local mock_picker = { close = spy.new() }
      picker_mock.create.invokes(function(opts, cb)
        -- assert.are.same(config.options, opts)
        cb(mock_picker, { text = "/test", category = "basic" })
        return mock_picker
      end)

      nvim_aider.api.open_command_picker()
      local match = require("luassert.match")
      assert.stub(picker_mock.create).was_called_with(nil, match.is_function())
      assert.stub(terminal_mock.command).was_called_with("/test", nil, nil)
      assert.spy(mock_picker.close).was_called()
    end)

    it("handles input commands with user input", function()
      local mock_picker = { close = spy.new() }
      picker_mock.create.invokes(function(opts, cb)
        cb(mock_picker, { text = "/input", category = "input" })
        return mock_picker
      end)
      input_stub.invokes(function(_, cb)
        cb("test input")
      end)

      nvim_aider.api.open_command_picker()
      assert.stub(terminal_mock.command).was_called_with("/input", "test input", nil)
    end)

    it("handles canceled input", function()
      local mock_picker = { close = spy.new() }
      picker_mock.create.invokes(function(_, cb)
        cb(mock_picker, { text = "/input", category = "input" })
        return mock_picker
      end)
      input_stub.invokes(function(_, cb)
        cb(nil)
      end)

      nvim_aider.api.open_command_picker()
      assert.stub(terminal_mock.command).was_not_called()
    end)
  end)

  describe("Error Handling", function()
    it("handles missing file in buffer operations", function()
      utils_mock.get_absolute_path.returns(nil)
      local notify_spy = spy.on(vim, "notify")

      nvim_aider.api.add_current_file()
      assert.stub(terminal_mock.command).was_not_called()
      assert.spy(notify_spy).was_called_with("No valid file in current buffer", vim.log.levels.INFO)
    end)

    it("handles invalid buffer for read-only", function()
      utils_mock.get_absolute_path.returns(nil)
      local notify_spy = spy.on(vim, "notify")

      nvim_aider.api.add_read_only_file()
      assert.stub(terminal_mock.command).was_not_called()
      assert.spy(notify_spy).was_called_with("No valid file in current buffer", vim.log.levels.INFO)
    end)
  end)
end)
