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

return M
