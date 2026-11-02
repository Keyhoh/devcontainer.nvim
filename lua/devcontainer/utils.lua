local M = {}

local config = {}

function M.log(level, msg)
  if config.log_level and (
    level == "error" or
    (level == "info" and config.log_level ~= "error") or
    (level == "debug" and config.log_level == "debug")
  ) then
    vim.notify("[devcontainer] " .. msg, vim.log.levels[string.upper(level)])
  end
end

function M.set_config(opts)
  config = vim.tbl_extend("force", {
    log_level = "error",
  }, opts or {})
end

function M.get_config()
  return config
end

function M.ensure_devcontainer_available()
  if vim.fn.executable("devcontainer") ~= 1 then
    M.log("error", "devcontainer CLI is not installed or not in PATH")
    return false
  end
  return true
end

return M
