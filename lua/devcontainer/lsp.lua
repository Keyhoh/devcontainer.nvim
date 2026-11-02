local M = {}

local cli = require("devcontainer.cli")
local utils = require("devcontainer.utils")
local detection = require("devcontainer.detection")

local started_containers = {}

local function ensure_container_running(workspace)
  workspace = workspace or vim.fn.getcwd()

  if started_containers[workspace] then
    return true
  end

  utils.log("debug", "Ensuring container is running for workspace: " .. workspace)
  if not cli.up() then
    utils.log("error", "Failed to start Dev Container for workspace: " .. workspace)
    return false
  end

  started_containers[workspace] = true
  utils.log("debug", "Container is now running for workspace: " .. workspace)
  return true
end

function M.wrap_lsp_cmd(cmd, workspace)
  if not cmd or #cmd == 0 then
    utils.log("error", "LSP command array is required")
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

  utils.log("debug", "Wrapping LSP command: " .. table.concat(cmd, " "))

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

function M.create_lsp_wrapper(workspace)
  workspace = workspace or vim.fn.getcwd()

  return function(cmd)
    return M.wrap_lsp_cmd(cmd, workspace)
  end
end

return M
