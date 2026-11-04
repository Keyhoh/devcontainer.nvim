local M = {}

local cli = require("devcontainer.cli")
local cmd_wrapper = require("devcontainer.cmd_wrapper")
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
      vim.notify("Usage: :Devcontainer {up|exec|build|restart} [args]", vim.log.levels.INFO)
      return
    end

    if subcommand == "up" then
      local async = true
      for i = 2, #opts_arg.fargs do
        if opts_arg.fargs[i] == "--sync" then
          async = false
          break
        end
      end

      if async then
        cli.up(true)
        vim.notify("Starting Dev Container in background...", vim.log.levels.INFO)
      else
        local success = cli.up(false)
        if success then
          vim.notify("Dev Container started successfully", vim.log.levels.INFO)
        else
          vim.notify("Failed to start Dev Container", vim.log.levels.ERROR)
        end
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

      -- Create a new buffer for each exec to avoid "requires unmodified buffer" error
      vim.cmd("enew")
      vim.fn.termopen(wrapped_cmd)
    elseif subcommand == "build" then
      local async = true
      for i = 2, #opts_arg.fargs do
        if opts_arg.fargs[i] == "--sync" then
          async = false
          break
        end
      end

      if async then
        cli.build(true)
        vim.notify("Building Dev Container in background...", vim.log.levels.INFO)
      else
        local success = cli.build(false)
        if success then
          vim.notify("Dev Container built successfully", vim.log.levels.INFO)
        else
          vim.notify("Failed to build Dev Container", vim.log.levels.ERROR)
        end
      end
    elseif subcommand == "restart" then
      local should_build = false
      local async = true
      for i = 2, #opts_arg.fargs do
        if opts_arg.fargs[i] == "--build" or opts_arg.fargs[i] == "-b" then
          should_build = true
        elseif opts_arg.fargs[i] == "--sync" then
          async = false
        end
      end

      if async then
        cli.restart(should_build, true)
        vim.notify("Restarting Dev Container in background...", vim.log.levels.INFO)
      else
        local success = cli.restart(should_build, false)
        if success then
          vim.notify("Dev Container restarted successfully", vim.log.levels.INFO)
        else
          vim.notify("Failed to restart Dev Container", vim.log.levels.ERROR)
        end
      end
    else
      vim.notify("Unknown subcommand: " .. subcommand, vim.log.levels.ERROR)
    end
  end, {
    desc = "Dev Container subcommands (up, exec, build, restart)",
    nargs = "+",
    complete = function(_, cmd_line)
      local subcommands = { "up", "exec", "build", "restart" }
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

-- Command execution functions
M.exec_cmd = cmd_wrapper.exec_cmd
M.create_exec_wrapper = cmd_wrapper.create_exec_wrapper

function M.wrap_for_lsp(config, workspace)
  workspace = workspace or vim.fn.getcwd()

  if not config or not config.cmd then
    return config
  end

  local wrapped_cmd = M.exec_cmd(config.cmd, workspace)
  if wrapped_cmd then
    local new_config = vim.tbl_extend("force", config, { cmd = wrapped_cmd })
    return new_config
  end

  return config
end
return M
