config = require("nvim_aider.config")

describe("AiderQuickSendCommand", function()
  local assert = require("luassert")
  local mock = require("luassert.mock")
  local spy = require("luassert.spy")
  local stub = require("luassert.stub")
  local terminal_mock
  local picker_mock

  local nvim_aider = require("nvim_aider")
  before_each(function()
    terminal_mock = mock(require("nvim_aider.terminal"), true)
    picker_mock = mock(require("nvim_aider.picker"), true)

    package.loaded["nvim_aider.commands"] = {
      test_command = { value = "/test", description = "Test command", category = "basic" },
      input_command = { value = "/input", description = "Input command", category = "input" },
    }

    vim.ui.input = stub.new()
  end)

  after_each(function()
    package.loaded["nvim_aider.commands"] = nil
    mock.revert(terminal_mock)
    mock.revert(picker_mock)
    vim.ui.input:revert()
  end)

  it("sends a basic command to the terminal", function()
    nvim_aider.setup()

    local mock_close = spy.new(function() end)
    local mock_picker = { close = mock_close }

    picker_mock.create.invokes(function(_, confirm_callback)
      confirm_callback(mock_picker, { text = "/test", category = "basic" })
      return mock_picker
    end)

    require("nvim_aider.api").open_command_picker()
    assert.stub(terminal_mock.command).was_called_with("/test", nil, nil)
    assert.spy(mock_close).was_called()
  end)

  it("handles canceled input gracefully", function()
    nvim_aider.setup()

    local mock_close = spy.new(function() end)
    local mock_picker = { close = mock_close }

    picker_mock.create.invokes(function(_, confirm_callback)
      confirm_callback(mock_picker, { text = "/input", category = "input" })
      return mock_picker
    end)

    vim.ui.input.invokes(function(_, callback)
      callback(nil) -- Simulate canceled input
    end)

    require("nvim_aider.api").open_command_picker()
    assert.stub(terminal_mock.command).was_not_called() -- Verify no command sent
    assert.spy(mock_close).was_called()
  end)

  it("sends a command with input to the terminal", function()
    nvim_aider.setup()
    local mock_close = spy.new(function() end)
    local mock_picker = { close = mock_close }

    picker_mock.create.invokes(function(_, confirm_callback)
      confirm_callback(mock_picker, { text = "/input", category = "input" })
      return mock_picker
    end)

    vim.ui.input.invokes(function(opts, callback)
      assert.equals("Enter input for `/input` (empty to skip):", opts.prompt) -- Verify prompt text
      callback("user_input")
    end)

    require("nvim_aider.api").open_command_picker()
    assert.stub(terminal_mock.command).was_called_with("/input", "user_input", nil)
    assert.spy(mock_close).was_called() -- Verify picker closed
  end)
end)
