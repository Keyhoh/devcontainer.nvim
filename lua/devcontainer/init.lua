local M = {}

local cmd_exec = require("devcontainer.cmd_exec")
local devcontainer_command = require("devcontainer.commands.devcontainer_command")
local init_loader = require("devcontainer.bootstrap.init_loader")
local lifecycle = require("devcontainer.cli.lifecycle")
local detection = require("devcontainer.detection")
local state = require("devcontainer.state")
local utils = require("devcontainer.utils")
local path_map = require("devcontainer.path_map")

local unpack = table.unpack or unpack

local function resolve_workspace_candidate(value)
  if type(value) ~= "string" or value == "" then
    return nil
  end
  return detection.find_workspace_root(value)
end

local function workspace_from_uri(uri)
  if type(uri) ~= "string" or uri == "" then
    return nil
  end

  local ok, fname = pcall(vim.uri_to_fname, uri)
  if not ok or type(fname) ~= "string" or fname == "" then
    return nil
  end

  local stat = vim.loop.fs_stat(fname)
  if stat and stat.type == "directory" then
    return resolve_workspace_candidate(fname)
  end

  return resolve_workspace_candidate(vim.fn.fnamemodify(fname, ":h"))
end

local function resolve_lsp_workspace(opts, lsp_config, params, root_dir)
  local candidates = {}

  table.insert(candidates, root_dir)
  if lsp_config then
    table.insert(candidates, lsp_config.root_dir)
    table.insert(candidates, workspace_from_uri(lsp_config.root_uri))
    if type(lsp_config.workspace_folders) == "table" then
      local first = lsp_config.workspace_folders[1]
      if type(first) == "table" then
        table.insert(candidates, workspace_from_uri(first.uri))
      end
    end
  end

  if params then
    table.insert(candidates, workspace_from_uri(params.rootUri))
    if type(params.workspaceFolders) == "table" then
      local first = params.workspaceFolders[1]
      if type(first) == "table" then
        table.insert(candidates, workspace_from_uri(first.uri))
      end
    end
  end

  if opts then
    table.insert(candidates, opts.workspace_folder)
  end
  table.insert(candidates, vim.fn.getcwd())

  for _, candidate in ipairs(candidates) do
    local workspace = resolve_workspace_candidate(candidate)
    if workspace then
      return workspace
    end
  end

  return vim.fn.getcwd()
end

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
  local base_cmd = vim.deepcopy(config.cmd)

  local function build_wrap_for_workspace(workspace)
    local mapper = path_map.create_mapper(workspace, opts)
    local mapped_cmd = mapper.map_cmd(vim.deepcopy(base_cmd))
    local exec_opts = vim.tbl_extend("force", opts, { workspace_folder = workspace })
    local wrapped_cmd = M.exec_cmd(mapped_cmd, exec_opts)
    return wrapped_cmd or mapped_cmd, mapper
  end

  local initial_workspace = resolve_lsp_workspace(opts, config, nil, nil)
  local wrapped_cmd, initial_mapper = build_wrap_for_workspace(initial_workspace)
  if wrapped_cmd then
    local original_before_init = config.before_init
    local original_on_new_config = config.on_new_config
    local original_on_init = config.on_init

    local new_config = vim.tbl_extend("force", config, {
      cmd = wrapped_cmd,
      before_init = function(params, lsp_config)
        if original_before_init then
          original_before_init(params, lsp_config)
        end

        local workspace = resolve_lsp_workspace(opts, lsp_config, params, nil)
        local mapper = path_map.create_mapper(workspace, opts)
        mapper.map_table_in_place(params)
        if lsp_config then
          lsp_config._devcontainer_path_mapper = mapper
        end
      end,
      on_new_config = function(new_lsp_config, root_dir)
        if original_on_new_config then
          original_on_new_config(new_lsp_config, root_dir)
        end

        if new_lsp_config then
          local workspace = resolve_lsp_workspace(opts, new_lsp_config, nil, root_dir)
          local refreshed_cmd, refreshed_mapper = build_wrap_for_workspace(workspace)
          new_lsp_config.cmd = refreshed_cmd
          new_lsp_config._devcontainer_path_mapper = refreshed_mapper

          if type(new_lsp_config.root_dir) == "string" then
            new_lsp_config.root_dir = refreshed_mapper.map_string(new_lsp_config.root_dir)
          end

          if type(new_lsp_config.root_uri) == "string" then
            new_lsp_config.root_uri = refreshed_mapper.map_string(new_lsp_config.root_uri)
          end

          if type(new_lsp_config.workspace_folders) == "table" then
            refreshed_mapper.map_table_in_place(new_lsp_config.workspace_folders)
          end
        end
      end,
      on_init = function(client, init_result)
        local workspace = resolve_lsp_workspace(opts, client and client.config or nil, nil, nil)
        local mapper = path_map.create_mapper(workspace, opts)

        if client and client.config then
          client.config._devcontainer_path_mapper = mapper
        end

        if client and client.rpc then
          local raw_notify = client.rpc.notify
          local raw_request = client.rpc.request

          if raw_notify and not client.rpc._devcontainer_notify_wrapped then
            client.rpc.notify = function(...)
              local argc = select("#", ...)
              local args = table.pack(...)
              local method_idx = type(args[1]) == "string" and 1 or 2
              local params_idx = method_idx + 1

              mapper.map_table_in_place(args[params_idx])
              return raw_notify(unpack(args, 1, argc))
            end
            client.rpc._devcontainer_notify_wrapped = true
          end

          if raw_request and not client.rpc._devcontainer_request_wrapped then
            client.rpc.request = function(...)
              local argc = select("#", ...)
              local args = table.pack(...)
              local method_idx = type(args[1]) == "string" and 1 or 2
              local params_idx = method_idx + 1
              local callback_idx = params_idx + 1

              mapper.map_table_in_place(args[params_idx])

              local callback = args[callback_idx]
              if type(callback) == "function" then
                args[callback_idx] = function(err, result, ctx, request_config)
                  mapper.map_table_to_host_in_place(result)
                  callback(err, result, ctx, request_config)
                end
              end

              return raw_request(unpack(args, 1, argc))
            end
            client.rpc._devcontainer_request_wrapped = true
          end
        end

        if original_on_init then
          return original_on_init(client, init_result)
        end
      end,
    })

    local mapper = initial_mapper
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
