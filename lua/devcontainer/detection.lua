local M = {}

local function file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil
end

local function find_root(start_path)
  local current = start_path
  
  while current ~= "/" do
    if file_exists(current .. "/.git") or
       file_exists(current .. "/.devcontainer") or
       file_exists(current .. "/.devcontainer.json") then
      return current
    end
    
    local parent = vim.fn.fnamemodify(current, ":h")
    if parent == current then
      break
    end
    current = parent
  end
  
  return start_path
end

function M.find_workspace_root(path)
  path = path or vim.fn.getcwd()
  return find_root(path)
end

function M.has_devcontainer(workspace)
  workspace = workspace or M.find_workspace_root()
  
  if file_exists(workspace .. "/.devcontainer/devcontainer.json") then
    return true, workspace .. "/.devcontainer/devcontainer.json"
  end
  
  if file_exists(workspace .. "/.devcontainer.json") then
    return true, workspace .. "/.devcontainer.json"
  end
  
  return false, nil
end

return M
