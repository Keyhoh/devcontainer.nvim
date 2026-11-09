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
  workspace = M.find_workspace_root(workspace or vim.fn.getcwd())

  if file_exists(workspace .. "/.devcontainer/devcontainer.json") then
    return true, workspace .. "/.devcontainer/devcontainer.json"
  end

  if file_exists(workspace .. "/.devcontainer.json") then
    return true, workspace .. "/.devcontainer.json"
  end

  return false, nil
end

function M.find_init_file(workspace)
  workspace = M.find_workspace_root(workspace or vim.fn.getcwd())

  local init_lua = workspace .. "/.devcontainer/init.lua"
  if file_exists(init_lua) then
    return init_lua
  end

  local init_vim = workspace .. "/.devcontainer/init.vim"
  if file_exists(init_vim) then
    return init_vim
  end

  return nil
end

return M
