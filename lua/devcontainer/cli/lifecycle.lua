local M = {}

local utils = require("devcontainer.utils")

local function run_async(cmd, callback, workspace)
  utils.log("info", "Running: " .. table.concat(cmd, " "))

  local job_id = vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code, _)
      if exit_code == 0 then
        utils.log("info", "Successfully completed")
        if callback then
          callback(true)
        end
      else
        utils.log("error", "Command failed with exit code: " .. exit_code)
        if callback then
          callback(false)
        end
      end
    end,
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= "" then
          utils.log("debug", "[stdout] " .. line)
        end
      end
    end,
    on_stderr = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= "" then
          utils.log("debug", "[stderr] " .. line)
        end
      end
    end,
  })

  if job_id <= 0 then
    utils.log("error", "Failed to start job")
    if callback then
      callback(false)
    end
    return false
  end

  vim.notify("[devcontainer] Operation started. Check logs for progress.", vim.log.levels.INFO)
  return true
end

function M.up(async, callback)
  if not utils.ensure_devcontainer_available() then
    if callback then
      callback(false)
    end
    return false
  end

  local workspace = vim.fn.getcwd()
  utils.log("debug", "Starting Dev Container for workspace: " .. workspace)

  local cmd = {
    "devcontainer",
    "up",
    "--workspace-folder",
    workspace,
  }

  if async == false then
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      utils.log("error", "Failed to start Dev Container: " .. result)
      if callback then
        callback(false)
      end
      return false
    end
    utils.log("debug", "Dev Container started successfully")
    if callback then
      callback(true)
    end
    return true
  else
    return run_async(cmd, callback, workspace)
  end
end

function M.build(async, callback)
  if not utils.ensure_devcontainer_available() then
    if callback then
      callback(false)
    end
    return false
  end

  local workspace = vim.fn.getcwd()
  utils.log("debug", "Building Dev Container for workspace: " .. workspace)

  local cmd = {
    "devcontainer",
    "build",
    "--workspace-folder",
    workspace,
  }

  if async == false then
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      utils.log("error", "Failed to build Dev Container: " .. result)
      if callback then
        callback(false)
      end
      return false
    end
    utils.log("debug", "Dev Container built successfully")
    if callback then
      callback(true)
    end
    return true
  else
    return run_async(cmd, callback, workspace)
  end
end

function M.restart(should_build, async, callback)
  if not utils.ensure_devcontainer_available() then
    if callback then
      callback(false)
    end
    return false
  end

  local workspace = vim.fn.getcwd()

  local function do_restart()
    if should_build then
      utils.log("debug", "Building Dev Container before restart")
      local build_result = vim.fn.system({
        "devcontainer",
        "build",
        "--workspace-folder",
        workspace,
      })

      if vim.v.shell_error ~= 0 then
        utils.log("error", "Failed to build Dev Container: " .. build_result)
        return false
      end

      utils.log("debug", "Dev Container built successfully")
    end

    utils.log("debug", "Restarting Dev Container for workspace: " .. workspace)

    local result = vim.fn.system({
      "devcontainer",
      "down",
      "--workspace-folder",
      workspace,
    })

    if vim.v.shell_error ~= 0 then
      utils.log("error", "Failed to stop Dev Container: " .. result)
      return false
    end

    utils.log("debug", "Dev Container stopped, starting again...")

    local result2 = vim.fn.system({
      "devcontainer",
      "up",
      "--workspace-folder",
      workspace,
    })

    if vim.v.shell_error ~= 0 then
      utils.log("error", "Failed to start Dev Container: " .. result2)
      return false
    end

    utils.log("debug", "Dev Container restarted successfully")
    return true
  end

  if async == false then
    local success = do_restart()
    if callback then
      callback(success)
    end
    return success
  else
    return run_async({
      "sh",
      "-c",
      (should_build and "devcontainer build --workspace-folder " .. workspace .. " && " or "") ..
      "devcontainer down --workspace-folder " .. workspace .. " && " ..
      "devcontainer up --workspace-folder " .. workspace
    }, callback, workspace)
  end
end

return M

