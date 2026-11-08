local M = {}

function M.build(workspace)
  return {
    "devcontainer",
    "build",
    "--workspace-folder",
    workspace,
  }
end

function M.up(workspace, opts)
  opts = opts or {}

  local cmd = {
    "devcontainer",
    "up",
    "--workspace-folder",
    workspace,
  }

  if opts.remove_existing_container then
    table.insert(cmd, "--remove-existing-container")
  end

  return cmd
end

return M
