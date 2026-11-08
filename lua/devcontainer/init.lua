local M = {}

local cmd_exec = require("devcontainer.cmd_exec")
local devcontainer_command = require("devcontainer.commands.devcontainer_command")
local init_loader = require("devcontainer.bootstrap.init_loader")
local utils = require("devcontainer.utils")

function M.setup(opts)
  utils.set_config(opts or {})
  init_loader.load()
  devcontainer_command.register()
end

-- Command execution functions
M.exec_cmd = cmd_exec.exec_cmd
M.create_exec_wrapper = cmd_exec.create_exec_wrapper

function M.wrap_for_lsp(config, opts)
  if not config or not config.cmd then
    return config
  end

  local wrapped_cmd = M.exec_cmd(config.cmd, opts)
  if wrapped_cmd then
    local new_config = vim.tbl_extend("force", config, { cmd = wrapped_cmd })
    return new_config
  end

  return config
end
return M
