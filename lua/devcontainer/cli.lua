local M = {}

-- Thin wrapper to build args for devcontainer cli
function M.up_args(workspace)
  return {"devcontainer", "up", "--workspace-folder", workspace}
end

function M.exec_args(workspace, cmd)
  local args = {"devcontainer", "exec", "--workspace-folder", workspace}
  for _, v in ipairs(cmd) do table.insert(args, v) end
  return args
end

return M
