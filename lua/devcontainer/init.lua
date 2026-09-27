local detection = require('devcontainer.detection')
local lsp = require('devcontainer.lsp')
local M = {}

M.config = {
  auto_start = true,
  log_level = "error",
}

local function notify(msg, level)
  if _G.vim and vim.notify then
    vim.notify(msg, level or vim.log.levels.INFO)
  end
end

function M.setup(cfg)
  cfg = cfg or {}
  for k, v in pairs(cfg) do
    M.config[k] = v
  end
end

-- Given an LSP config table, return a shallow-copied config with cmd wrapped for devcontainer
function M.wrap_lsp_config(config, workspace)
  if not config or type(config) ~= 'table' then return config end
  if not config.cmd or type(config.cmd) ~= 'table' then return config end

  local ws = workspace or detection.find_workspace_root()
  if not ws then return config end

  local new = {}
  for k, v in pairs(config) do new[k] = v end
  new.cmd = lsp.wrap_cmd(config.cmd, ws)
  return new
end

-- Wrap a server from lspconfig. Usage: require('devcontainer').wrap_lsp('gopls', opts)
-- This ensures the devcontainer is started (async) and then calls lspconfig[server].setup with wrapped cmd.
function M.wrap_lsp(server_name, opts)
  local ok, lspconfig = pcall(require, 'lspconfig')
  if not ok then
    notify('lspconfig not found; cannot wrap LSP server: ' .. tostring(server_name), vim.log.levels.ERROR)
    return
  end

  opts = opts or {}
  local ws = detection.find_workspace_root()
  if not ws then
    -- no devcontainer detected; fall back to normal setup
    lspconfig[server_name].setup(opts)
    return
  end

  local wrapped_opts = M.wrap_lsp_config(opts, ws)
  local cli = require('devcontainer.cli')

  local function do_setup()
    -- call setup once
    if lspconfig[server_name] and type(lspconfig[server_name].setup) == 'function' then
      lspconfig[server_name].setup(wrapped_opts)
    else
      notify('lspconfig does not expose setup for ' .. tostring(server_name), vim.log.levels.ERROR)
    end
  end

  local handle = nil
  local ok2, err = pcall(function()
    handle = cli.up(ws, function(code, signal)
      -- ignore exit code; attempt to setup regardless
      do_setup()
    end)
  end)
  if not ok2 then
    notify('failed to start devcontainer up: ' .. tostring(err), vim.log.levels.WARN)
    do_setup()
    return
  end

  if not handle then
    -- synchronous fallback; setup already
    do_setup()
  end
end

return M
