local uv = vim.loop
local M = {}

-- Find workspace root by looking for a marker (e.g. .devcontainer)
function M.find_workspace_root(start_path)
  local path = start_path or vim.fn.expand('%:p:h')
  if path == nil or path == '' then return nil end
  local sep = package.config:sub(1,1)
  local function exists(p)
    local stat = uv.fs_stat(p)
    return stat ~= nil
  end

  local cur = path
  while cur and cur ~= '' and cur ~= sep do
    if exists(cur .. sep .. '.devcontainer') or exists(cur .. sep .. '.devcontainer.json') then
      return cur
    end
    local parent = cur:match("(.*") .. sep .. "[^"]+$")
    if not parent or parent == cur then break end
    cur = parent
  end
  return nil
end

return M
