local M = {}

local detection = require("devcontainer.detection")

function M.load()
  local init_file = detection.find_init_file()

  if not init_file then
    return
  end

  if init_file:match("%.lua$") then
    local ok, err = pcall(function()
      dofile(init_file)
    end)
    if not ok then
      vim.notify("[devcontainer] Error loading init.lua: " .. tostring(err), vim.log.levels.ERROR)
    end
  elseif init_file:match("%.vim$") then
    local ok, err = pcall(function()
      vim.cmd("source " .. init_file)
    end)
    if not ok then
      vim.notify("[devcontainer] Error loading init.vim: " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

return M
