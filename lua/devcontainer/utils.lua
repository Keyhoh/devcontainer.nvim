local M = {}

local config = {}
local log_file_name = "devcontainer.nvim.log"

local function log_file_path()
  return vim.fn.stdpath("cache") .. "/" .. log_file_name
end

local function append_log(level, msg)
  local path = log_file_path()
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local fh, err = io.open(path, "a")
  if not fh then
    vim.notify("[devcontainer] Failed to write log file: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  local ts = os.date("%Y-%m-%d %H:%M:%S")
  fh:write(string.format("%s [%s] %s\n", ts, string.upper(level), msg))
  fh:close()
end

function M.log(level, msg)
  if level ~= "debug" or config.log_level == "debug" then
    append_log(level, msg)
  end

  if config.log_level and (level == "error" or (level == "info" and config.log_level ~= "error")) then
    vim.notify("[devcontainer] " .. msg, vim.log.levels[string.upper(level)])
  end
end

function M.set_config(opts)
  config = vim.tbl_extend("force", {
    auto_start = true,
    log_level = "error",
  }, opts or {})
end

function M.get_config()
  return config
end

function M.get_log_file_path()
  return log_file_path()
end

function M.clear_log_file()
  local path = log_file_path()
  local fh, err = io.open(path, "w")
  if not fh then
    M.log("error", "Failed to clear log file: " .. tostring(err))
    return false
  end
  fh:close()
  return true
end

function M.open_log_float()
  local path = log_file_path()
  local lines = {}

  if vim.fn.filereadable(path) == 1 then
    lines = vim.fn.readfile(path)
  else
    lines = { "No log file yet: " .. path }
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "devcontainer://logs")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "log"

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = row,
    col = col,
    title = " devcontainer.nvim logs ",
    title_pos = "center",
  })

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
end

function M.ensure_devcontainer_available()
  if vim.fn.executable("devcontainer") ~= 1 then
    M.log("error", "devcontainer CLI is not installed or not in PATH")
    return false
  end
  return true
end

return M
