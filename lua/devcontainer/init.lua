local M = {}

local cli = require("devcontainer.cli")
local lsp = require("devcontainer.lsp")

function M.setup(opts)
  cli.setup(opts or {})

  vim.api.nvim_create_user_command("DevcontainerUp", function()
    local success = cli.up()
    if success then
      vim.notify("Dev Container started successfully", vim.log.levels.INFO)
    else
      vim.notify("Failed to start Dev Container", vim.log.levels.ERROR)
    end
  end, {
    desc = "Start Dev Container for current workspace",
  })

  vim.api.nvim_create_user_command("DevcontainerExec", function(opts)
    local args = vim.split(opts.args, " ")
    local wrapped_cmd = cli.exec(args)
    if not wrapped_cmd then
      vim.notify("Failed to prepare devcontainer exec command", vim.log.levels.ERROR)
      return
    end

    vim.fn.termopen(wrapped_cmd)
  end, {
    desc = "Execute command in Dev Container (interactive terminal)",
    nargs = "+",
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
