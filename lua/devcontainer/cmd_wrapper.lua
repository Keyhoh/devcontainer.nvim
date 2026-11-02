local M = {}

local cli = require("devcontainer.cli")
local utils = require("devcontainer.utils")
local detection = require("devcontainer.detection")

local started_containers = {}

local function ensure_container_running(workspace, callback)
  workspace = workspace or vim.fn.getcwd()

  if started_containers[workspace] then
    if callback then
      callback(true)
    end
    return true
  end

  utils.log("debug", "Ensuring container is running for workspace: " .. workspace)

  local function on_container_ready(success)
    if success then
      started_containers[workspace] = true
      utils.log("debug", "Container is now running for workspace: " .. workspace)
      if callback then
        callback(true)
      end
    else
      utils.log("error", "Failed to start Dev Container for workspace: " .. workspace)
      if callback then
        callback(false)
      end
    end
  end

  cli.up(true, on_container_ready)
  return false
end

function M.wrap_cmd(cmd, workspace)
  if not cmd or #cmd == 0 then
    utils.log("error", "Command array is required")
    return cmd
  end

  workspace = workspace or vim.fn.getcwd()

  local has_dc, dc_path = detection.has_devcontainer(workspace)
  if not has_dc then
    utils.log("debug", "No Dev Container found for workspace: " .. workspace)
    return cmd
  end

  utils.log("debug", "Dev Container detected at: " .. dc_path)

  if not ensure_container_running(workspace) then
    return nil
  end

  utils.log("debug", "Wrapping command: " .. table.concat(cmd, " "))

  local wrapped = {
    "devcontainer",
    "exec",
    "--workspace-folder",
    workspace,
  }

  for _, arg in ipairs(cmd) do
    table.insert(wrapped, arg)
  end

  utils.log("debug", "Wrapped command: " .. table.concat(wrapped, " "))

  return wrapped
end

function M.create_wrapper(workspace)
  workspace = workspace or vim.fn.getcwd()

  return function(cmd)
    return M.wrap_cmd(cmd, workspace)
  end
end

return M
