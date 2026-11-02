local M = {}

local utils = require("devcontainer.utils")

function M.exec(cmd)
  if not utils.ensure_devcontainer_available() then
    return nil
  end

  if not cmd or #cmd == 0 then
    utils.log("error", "command is required")
    return nil
  end

  local workspace = vim.fn.getcwd()
  utils.log("debug", "Preparing devcontainer exec for workspace: " .. workspace)
  utils.log("debug", "Original command: " .. table.concat(cmd, " "))

  local wrapped_cmd = {
    "devcontainer",
    "exec",
    "--workspace-folder",
    workspace,
  }

  for _, arg in ipairs(cmd) do
    table.insert(wrapped_cmd, arg)
  end

  utils.log("debug", "Wrapped command: " .. table.concat(wrapped_cmd, " "))

  return wrapped_cmd
end

function M.wrap_cmd(cmd)
  if not cmd or #cmd == 0 then
    utils.log("error", "command array is required")
    return cmd
  end

  return M.exec(cmd)
end

return M

