local M = {}

local utils = require("devcontainer.utils")

function M.run_sync(cmd, callback, success_message, error_prefix)
  utils.log("info", "Running: " .. table.concat(cmd, " "))

  local exit_code = nil
  local job_id = vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      exit_code = code
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

  vim.fn.jobwait({ job_id }, 300000)

  if exit_code == 0 then
    if success_message then
      utils.log("debug", success_message)
    end
    if callback then
      callback(true)
    end
    return true
  else
    utils.log("error", error_prefix .. "command failed with exit code: " .. tostring(exit_code))
    if callback then
      callback(false)
    end
    return false
  end
end

function M.run_async(cmd, callback)
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

return M
