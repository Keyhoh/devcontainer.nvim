local M = {}

local config = {}

local function log(level, msg)
  if config.log_level and (
    level == "error" or
    (level == "info" and config.log_level ~= "error") or
    (level == "debug" and config.log_level == "debug")
  ) then
    vim.notify("[devcontainer] " .. msg, vim.log.levels[string.upper(level)])
  end
end

local function ensure_devcontainer_available()
  if vim.fn.executable("devcontainer") ~= 1 then
    log("error", "devcontainer CLI is not installed or not in PATH")
    return false
  end
  return true
end

function M.setup(opts)
  config = vim.tbl_extend("force", {
    log_level = "error",
  }, opts or {})
end

function M.up()
  if not ensure_devcontainer_available() then
    return false
  end

  local workspace = vim.fn.getcwd()
  log("debug", "Starting Dev Container for workspace: " .. workspace)

  local result = vim.fn.system({
    "devcontainer",
    "up",
    "--workspace-folder",
    workspace,
  })

  if vim.v.shell_error ~= 0 then
    log("error", "Failed to start Dev Container: " .. result)
    return false
  end

  log("debug", "Dev Container started successfully")
  return true
end

function M.exec(cmd)
  if not ensure_devcontainer_available() then
    return nil
  end

  if not cmd or #cmd == 0 then
    log("error", "command is required")
    return nil
  end

  local workspace = vim.fn.getcwd()
  log("debug", "Preparing devcontainer exec for workspace: " .. workspace)
  log("debug", "Original command: " .. table.concat(cmd, " "))

  local wrapped_cmd = {
    "devcontainer",
    "exec",
    "--workspace-folder",
    workspace,
  }

  for _, arg in ipairs(cmd) do
    table.insert(wrapped_cmd, arg)
  end

  log("debug", "Wrapped command: " .. table.concat(wrapped_cmd, " "))

  return wrapped_cmd
end

function M.wrap_cmd(cmd)
  if not cmd or #cmd == 0 then
    log("error", "command array is required")
    return cmd
  end

  return M.exec(cmd)
end

return M
