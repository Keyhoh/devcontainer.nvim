local uv = vim and vim.loop
local M = {}

-- Build args for devcontainer cli
function M.up_args(workspace)
  return {"devcontainer", "up", "--workspace-folder", workspace}
end

function M.exec_args(workspace, cmd)
  local args = {"devcontainer", "exec", "--workspace-folder", workspace}
  for _, v in ipairs(cmd) do table.insert(args, v) end
  return args
end

-- Spawn a command using luv/vim.loop when available, otherwise fall back to os.execute
local function spawn(args, opts, on_exit)
  opts = opts or {}
  if uv and uv.spawn then
    local stdout = opts.stdout or nil
    local stderr = opts.stderr or nil
    local handle
    handle = uv.spawn(args[1], { args = { unpack(args, 2) } }, function(code, signal)
      if on_exit then on_exit(code, signal) end
      if handle then handle:close() end
    end)
    return handle
  else
    -- Fallback: join args safely (not for production) and run
    local cmd = table.concat(args, ' ')
    local ok = os.execute(cmd)
    if on_exit then on_exit(ok and 0 or 1, 0) end
    return nil
  end
end

-- Start (or ensure) the devcontainer is up. Callback receives (exit_code, signal)
function M.up(workspace, on_exit)
  local args = M.up_args(workspace)
  return spawn(args, nil, on_exit)
end

-- Execute a command inside the devcontainer. cmd is argv array.
function M.exec(workspace, cmd, on_exit)
  local args = M.exec_args(workspace, cmd)
  return spawn(args, nil, on_exit)
end

return M
