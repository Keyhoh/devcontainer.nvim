local M = {}

local container_states = {}

function M.get_container_state(workspace)
  return container_states[workspace]
end

function M.set_container_state(workspace, state)
  container_states[workspace] = state
end

return M
