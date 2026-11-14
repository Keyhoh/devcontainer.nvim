local M = {}

local cmd_exec = require("devcontainer.cmd_exec")
local devcontainer_command = require("devcontainer.commands.devcontainer_command")
local init_loader = require("devcontainer.bootstrap.init_loader")
local lifecycle = require("devcontainer.cli.lifecycle")
local detection = require("devcontainer.detection")
local state = require("devcontainer.state")
local utils = require("devcontainer.utils")

function M.setup(opts)
  utils.set_config(opts or {})
  init_loader.load()
  devcontainer_command.register()

  local config = utils.get_config()
  if config.auto_start == false then
    return
  end

  local workspace = vim.fn.getcwd()
  local has_dc = detection.has_devcontainer(workspace)
  local container_state = state.get_container_state(workspace)
  if has_dc and container_state ~= "starting" and container_state ~= "running" then
    state.set_container_state(workspace, "starting")
    lifecycle.up(true, function(success)
      if success then
        state.set_container_state(workspace, "running")
      else
        state.set_container_state(workspace, nil)
      end
    end, workspace)
  end
end

-- Command execution functions
M.exec_cmd = cmd_exec.exec_cmd
M.create_exec_wrapper = cmd_exec.create_exec_wrapper

return M
