local M = {}

local cli = require("devcontainer.cli")
local detection = require("devcontainer.detection")

local started_containers = {}

local function log(level, msg)
  local config = cli.get_config()
  if config.log_level and (
    level == "error" or
    (level == "info" and config.log_level ~= "error") or
    (level == "debug" and config.log_level == "debug")
  ) then
    vim.notify("[devcontainer] " .. msg, vim.log.levels[string.upper(level)])
  end
end

local function ensure_container_running(workspace)
  workspace = workspace or vim.fn.getcwd()
  
  if started_containers[workspace] then
    return true
  end
  
  log("debug", "Ensuring container is running for workspace: " .. workspace)
  if not cli.up() then
    log("error", "Failed to start Dev Container for workspace: " .. workspace)
    return false
  end
  
  started_containers[workspace] = true
  log("debug", "Container is now running for workspace: " .. workspace)
  return true
end

function M.wrap_lsp_cmd(cmd, workspace)
  if not cmd or #cmd == 0 then
    log("error", "LSP command array is required")
    return cmd
  end
  
  workspace = workspace or vim.fn.getcwd()
  
  local has_dc, dc_path = detection.has_devcontainer(workspace)
  if not has_dc then
    log("debug", "No Dev Container found for workspace: " .. workspace)
    return cmd
  end
  
  log("debug", "Dev Container detected at: " .. dc_path)
  
  if not ensure_container_running(workspace) then
    return nil
  end
  
  log("debug", "Wrapping LSP command: " .. table.concat(cmd, " "))
  
  local wrapped = {
    "devcontainer",
    "exec",
    "--workspace-folder",
    workspace,
  }
  
  for _, arg in ipairs(cmd) do
    table.insert(wrapped, arg)
  end
  
  log("debug", "Wrapped command: " .. table.concat(wrapped, " "))
  
  return wrapped
end

function M.create_lsp_wrapper(workspace)
  workspace = workspace or vim.fn.getcwd()
  
  return function(cmd)
    return M.wrap_lsp_cmd(cmd, workspace)
  end
end

return M
