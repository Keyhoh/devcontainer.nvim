local detection = require('devcontainer.detection')
local lsp = require('devcontainer.lsp')
local M = {}

M.config = {
  auto_start = true,
  log_level = "error",
}

function M.setup(cfg)
  cfg = cfg or {}
  for k, v in pairs(cfg) do
    M.config[k] = v
  end
end

-- Given an LSP config table, return a shallow-copied config with cmd wrapped for devcontainer
function M.wrap_lsp_config(config, workspace)
  if not config or type(config) ~= 'table' then return config end
  if not config.cmd or type(config.cmd) ~= 'table' then return config end

  local ws = workspace or detection.find_workspace_root()
  if not ws then return config end

  local new = {}
  for k, v in pairs(config) do new[k] = v end
  new.cmd = lsp.wrap_cmd(config.cmd, ws)
  return new
end

return M
