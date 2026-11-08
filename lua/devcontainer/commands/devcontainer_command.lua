local M = {}

local lifecycle = require("devcontainer.cli.lifecycle")
local exec = require("devcontainer.cli.exec")
local utils = require("devcontainer.utils")

local function parse_async_flag(args)
  local async = true
  for i = 2, #args do
    if args[i] == "--sync" then
      async = false
      break
    end
  end
  return async
end

local function handle_up(args)
  local async = parse_async_flag(args)
  if async then
    lifecycle.up(true)
    vim.notify("Starting Dev Container in background...", vim.log.levels.INFO)
    return
  end

  if lifecycle.up(false) then
    vim.notify("Dev Container started successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to start Dev Container", vim.log.levels.ERROR)
  end
end

local function handle_exec(args)
  local cmd_args = {}
  for i = 2, #args do
    table.insert(cmd_args, args[i])
  end

  if #cmd_args == 0 then
    vim.notify("Usage: :Devcontainer exec {cmd} [args]", vim.log.levels.INFO)
    return
  end

  local wrapped_cmd = exec.exec(cmd_args)
  if not wrapped_cmd then
    vim.notify("Failed to prepare devcontainer exec command", vim.log.levels.ERROR)
    return
  end

  vim.cmd("enew")
  vim.fn.termopen(wrapped_cmd)
end

local function handle_build(args)
  local async = parse_async_flag(args)
  if async then
    lifecycle.build(true)
    vim.notify("Building Dev Container in background...", vim.log.levels.INFO)
    return
  end

  if lifecycle.build(false) then
    vim.notify("Dev Container built successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to build Dev Container", vim.log.levels.ERROR)
  end
end

local function handle_restart(args)
  local should_build = false
  for i = 2, #args do
    if args[i] == "--build" or args[i] == "-b" then
      should_build = true
    end
  end

  local async = parse_async_flag(args)
  if async then
    lifecycle.restart(should_build, true)
    vim.notify("Restarting Dev Container in background...", vim.log.levels.INFO)
    return
  end

  if lifecycle.restart(should_build, false) then
    vim.notify("Dev Container restarted successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to restart Dev Container", vim.log.levels.ERROR)
  end
end

local function handle_logs(args)
  local should_clear = false
  for i = 2, #args do
    if args[i] == "--clear" then
      should_clear = true
      break
    end
  end

  if should_clear then
    if utils.clear_log_file() then
      vim.notify("Devcontainer logs cleared", vim.log.levels.INFO)
    end
    return
  end

  utils.open_log_float()
end

local handlers = {
  up = handle_up,
  exec = handle_exec,
  build = handle_build,
  restart = handle_restart,
  logs = handle_logs,
}

function M.register()
  vim.api.nvim_create_user_command("Devcontainer", function(opts)
    local subcommand = opts.fargs[1]
    if not subcommand then
      vim.notify("Usage: :Devcontainer {up|exec|build|restart|logs} [args]", vim.log.levels.INFO)
      return
    end

    local handler = handlers[subcommand]
    if not handler then
      vim.notify("Unknown subcommand: " .. subcommand, vim.log.levels.ERROR)
      return
    end

    handler(opts.fargs)
  end, {
    desc = "Dev Container subcommands (up, exec, build, restart, logs)",
    nargs = "+",
    complete = function(_, cmd_line)
      local subcommands = { "up", "exec", "build", "restart", "logs" }
      local parts = vim.split(cmd_line, " ")
      if #parts == 2 then
        return subcommands
      end
      return {}
    end,
  })
end

return M
