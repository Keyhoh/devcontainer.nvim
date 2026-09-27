local detection = require('devcontainer.detection')
local cli = require('devcontainer.cli')
local M = {}

function M.wrap_cmd(cmd, workspace)
  -- do not mutate input
  local copy = {}
  for i, v in ipairs(cmd) do copy[i] = v end
  return cli.exec_args(workspace, copy)
end

return M
