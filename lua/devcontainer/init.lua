local M = {}

local cli = require("devcontainer.cli")
local lsp = require("devcontainer.lsp")
local detection = require("devcontainer.detection")

local function load_devcontainer_init()
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

function M.setup(opts)
  cli.setup(opts or {})
  
  load_devcontainer_init()

  vim.api.nvim_create_user_command("Devcontainer", function(opts_arg)
    local subcommand = opts_arg.fargs[1]
    
    if not subcommand then
      vim.notify("Usage: :Devcontainer {up|exec} [args]", vim.log.levels.INFO)
      return
    end
    
    if subcommand == "up" then
      local success = cli.up()
      if success then
        vim.notify("Dev Container started successfully", vim.log.levels.INFO)
      else
        vim.notify("Failed to start Dev Container", vim.log.levels.ERROR)
      end
    elseif subcommand == "exec" then
      local args = {}
      for i = 2, #opts_arg.fargs do
        table.insert(args, opts_arg.fargs[i])
      end
      
      if #args == 0 then
        vim.notify("Usage: :Devcontainer exec {cmd} [args]", vim.log.levels.INFO)
        return
      end
      
      local wrapped_cmd = cli.exec(args)
      if not wrapped_cmd then
        vim.notify("Failed to prepare devcontainer exec command", vim.log.levels.ERROR)
        return
      end
      
      vim.fn.termopen(wrapped_cmd)
    else
      vim.notify("Unknown subcommand: " .. subcommand, vim.log.levels.ERROR)
    end
  end, {
    desc = "Dev Container subcommands (up, exec)",
    nargs = "+",
    complete = function(_, cmd_line)
      local subcommands = { "up", "exec" }
      local parts = vim.split(cmd_line, " ")
      if #parts == 2 then
        -- Completing subcommand
        return subcommands
      end
      -- No completion for args after subcommand
      return {}
    end,
  })
end

-- Direct export of LSP wrapping function
M.wrap_lsp_cmd = lsp.wrap_lsp_cmd

function M.wrap_for_lsp(config, workspace)
  workspace = workspace or vim.fn.getcwd()
  
  if not config or not config.cmd then
    return config
  end
  
  local wrapped_cmd = M.wrap_lsp_cmd(config.cmd, workspace)
  if wrapped_cmd then
    local new_config = vim.tbl_extend("force", config, { cmd = wrapped_cmd })
    return new_config
  end
  
  return config
end

return M
