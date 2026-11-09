local M = {}

local cmd_exec = require("devcontainer.cmd_exec")
local devcontainer_command = require("devcontainer.commands.devcontainer_command")
local init_loader = require("devcontainer.bootstrap.init_loader")
local lifecycle = require("devcontainer.cli.lifecycle")
local detection = require("devcontainer.detection")
local state = require("devcontainer.state")
local utils = require("devcontainer.utils")
local path_map = require("devcontainer.path_map")

function M.setup(opts)
  utils.set_config(opts or {})
  init_loader.load()
  devcontainer_command.register()

  local config = utils.get_config()
  if config.auto_start == false then
    return
  end

  local workspace = vim.fn.getcwd()
  local has_dc = detection.has_devcontainer(workspace)
  local container_state = state.get_container_state(workspace)
  if has_dc and container_state ~= "starting" and container_state ~= "running" then
    state.set_container_state(workspace, "starting")
    lifecycle.up(true, function(success)
      if success then
        state.set_container_state(workspace, "running")
      else
        state.set_container_state(workspace, nil)
      end
    end, workspace)
  end
end

-- Command execution functions
M.exec_cmd = cmd_exec.exec_cmd
M.create_exec_wrapper = cmd_exec.create_exec_wrapper

function M.wrap_for_lsp(config, opts)
  if not config or not config.cmd then
    return config
  end

  opts = opts or {}
  local workspace = opts.workspace_folder or vim.fn.getcwd()
  local mapper = path_map.create_mapper(workspace, opts)
  local mapped_cmd = mapper.map_cmd(config.cmd)

  local wrapped_cmd = M.exec_cmd(mapped_cmd, opts)
  if wrapped_cmd then
    local original_before_init = config.before_init
    local original_on_new_config = config.on_new_config

    local new_config = vim.tbl_extend("force", config, {
      cmd = wrapped_cmd,
      before_init = function(params, lsp_config)
        if original_before_init then
          original_before_init(params, lsp_config)
        end
        mapper.map_table_in_place(params)
      end,
      on_new_config = function(new_lsp_config, root_dir)
        if original_on_new_config then
          original_on_new_config(new_lsp_config, root_dir)
        end

        if new_lsp_config and new_lsp_config.cmd then
          local cmd = new_lsp_config.cmd
          if type(cmd) == "table" and not (cmd[1] == "devcontainer" and cmd[2] == "exec") then
            new_lsp_config.cmd = M.exec_cmd(mapper.map_cmd(new_lsp_config.cmd), opts)
          end
        end

        if new_lsp_config and type(new_lsp_config.root_dir) == "string" then
          new_lsp_config.root_dir = mapper.map_string(new_lsp_config.root_dir)
        end
      end,
    })

    if type(new_config.root_dir) == "string" then
      new_config.root_dir = mapper.map_string(new_config.root_dir)
    end

    if type(new_config.root_uri) == "string" then
      new_config.root_uri = mapper.map_string(new_config.root_uri)
    end

    if type(new_config.workspace_folders) == "table" then
      mapper.map_table_in_place(new_config.workspace_folders)
    end

    return new_config
  end

  return config
end
return M
