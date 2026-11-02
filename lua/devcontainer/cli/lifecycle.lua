local M = {}

local utils = require("devcontainer.utils")

function M.up()
  if not utils.ensure_devcontainer_available() then
    return false
  end

  local workspace = vim.fn.getcwd()
  utils.log("debug", "Starting Dev Container for workspace: " .. workspace)

  local result = vim.fn.system({
    "devcontainer",
    "up",
    "--workspace-folder",
    workspace,
  })

  if vim.v.shell_error ~= 0 then
    utils.log("error", "Failed to start Dev Container: " .. result)
    return false
  end

  utils.log("debug", "Dev Container started successfully")
  return true
end

function M.build()
  if not utils.ensure_devcontainer_available() then
    return false
  end

  local workspace = vim.fn.getcwd()
  utils.log("debug", "Building Dev Container for workspace: " .. workspace)

  local result = vim.fn.system({
    "devcontainer",
    "build",
    "--workspace-folder",
    workspace,
  })

  if vim.v.shell_error ~= 0 then
    utils.log("error", "Failed to build Dev Container: " .. result)
    return false
  end

  utils.log("debug", "Dev Container built successfully")
  return true
end

function M.restart(should_build)
  if not utils.ensure_devcontainer_available() then
    return false
  end

  local workspace = vim.fn.getcwd()

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

return M

