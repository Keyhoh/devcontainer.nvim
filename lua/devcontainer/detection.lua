local uv = vim and vim.loop or require('uv')
local M = {}

local function exists(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil
end

-- Find workspace root by looking for .devcontainer directory or .devcontainer.json file.
-- If start_path is nil, try to use current buffer's directory (Neovim) or uv.cwd().
function M.find_workspace_root(start_path)
  local start = start_path
  if not start or start == '' then
    if _G.vim and vim.fn and vim.fn.expand then
      start = vim.fn.expand('%:p:h')
    else
      local ok, cwd = pcall(uv.cwd)
      start = ok and cwd or nil
    end
  end
  if not start or start == '' then return nil end

  local cur = start
  while cur and cur ~= '' do
    local devcontainer_dir = cur .. '/.devcontainer'
    local devcontainer_file = cur .. '/.devcontainer.json'
    if exists(devcontainer_dir) or exists(devcontainer_file) then
      return cur
    end
    -- parent directory
    local parent = cur:match("^(.+)/[^/]+$")
    if not parent or parent == cur then break end
    cur = parent
  end
  return nil
end

return M
