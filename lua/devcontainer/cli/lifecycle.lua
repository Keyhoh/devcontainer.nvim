local M = {}

local utils = require("devcontainer.utils")
local commands = require("devcontainer.cli.commands")
local runner = require("devcontainer.cli.runner")

local function ensure_available(callback)
  if utils.ensure_devcontainer_available() then
    return true
  end

  if callback then
    callback(false)
  end
  return false
end

local function run_by_mode(async, cmd, callback, success_message, error_prefix)
  if async == false then
    return runner.run_sync(cmd, callback, success_message, error_prefix)
  end

  return runner.run_async(cmd, callback)
end

function M.up(async, callback, workspace)
  if not ensure_available(callback) then
    return false
  end

  workspace = workspace or vim.fn.getcwd()
  utils.log("debug", "Starting Dev Container for workspace: " .. workspace)

  return run_by_mode(
    async,
    commands.up(workspace),
    callback,
    "Dev Container started successfully",
    "Failed to start Dev Container: "
  )
end

function M.build(async, callback, workspace)
  if not ensure_available(callback) then
    return false
  end

  workspace = workspace or vim.fn.getcwd()
  utils.log("debug", "Building Dev Container for workspace: " .. workspace)

  return run_by_mode(
    async,
    commands.build(workspace),
    callback,
    "Dev Container built successfully",
    "Failed to build Dev Container: "
  )
end

function M.restart(should_build, async, callback)
  if not ensure_available(callback) then
    return false
  end

  local workspace = vim.fn.getcwd()
  local build_cmd = commands.build(workspace)
  local restart_cmd = commands.up(workspace, { remove_existing_container = true })

  local function run_restart_sync()
    if should_build then
      utils.log("debug", "Building Dev Container before restart")
      if not runner.run_sync(build_cmd, nil, "Dev Container built successfully", "Failed to build Dev Container: ") then
        if callback then
          callback(false)
        end
        return false
      end
    end

    utils.log("debug", "Restarting Dev Container for workspace: " .. workspace)
    return runner.run_sync(restart_cmd, callback, "Dev Container restarted successfully", "Failed to start Dev Container: ")
  end

  local function run_restart_async()
    if not should_build then
      return runner.run_async(restart_cmd, callback)
    end

    utils.log("debug", "Building Dev Container before restart")
    return runner.run_async(build_cmd, function(build_success)
      if not build_success then
        if callback then
          callback(false)
        end
        return
      end

      utils.log("debug", "Restarting Dev Container for workspace: " .. workspace)
      runner.run_async(restart_cmd, callback)
    end)
  end

  if async == false then
    return run_restart_sync()
  end

  return run_restart_async()
end

return M
