local M = {}

local cli = require("devcontainer.cli")
local utils = require("devcontainer.utils")
local detection = require("devcontainer.detection")

local started_containers = {}

-- Ensure the container is running.
-- Used by LSP and other tools that require container availability.
-- When async=true, starts the container in the background and returns immediately.
-- When async=false (default), blocks until the container is running.
local function ensure_container_running(workspace, async)
  workspace = workspace or vim.fn.getcwd()

  if started_containers[workspace] then
    return true
  end

  utils.log("debug", "Ensuring container is running for workspace: " .. workspace)

  if async then
    cli.up(true, function(success)
      if success then
        started_containers[workspace] = true
        utils.log("debug", "Container is now running for workspace: " .. workspace)
      end
    end)
    return true
  else
    if not cli.up(false) then
      utils.log("error", "Failed to start Dev Container for workspace: " .. workspace)
      return false
    end
    started_containers[workspace] = true
    utils.log("debug", "Container is now running for workspace: " .. workspace)
    return true
  end
end

function M.exec_cmd(cmd, workspace, opts)
  if not cmd or #cmd == 0 then
    utils.log("error", "Command array is required")
    return cmd
  end

  workspace = workspace or vim.fn.getcwd()
  opts = opts or {}

  local has_dc, dc_path = detection.has_devcontainer(workspace)
  if not has_dc then
    utils.log("debug", "No Dev Container found for workspace: " .. workspace)
    return cmd
  end

  utils.log("debug", "Dev Container detected at: " .. dc_path)

  if not ensure_container_running(workspace, opts.async) then
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

function M.create_exec_wrapper(workspace, opts)
  workspace = workspace or vim.fn.getcwd()
  opts = opts or {}

  return function(cmd)
    return M.exec_cmd(cmd, workspace, opts)
  end
end

return M
