local M = {}

local detection = require("devcontainer.detection")
local utils = require("devcontainer.utils")

local function path_exists(path)
  return path and vim.loop.fs_stat(path) ~= nil
end

local function normalize(path)
  if type(path) ~= "string" or path == "" then
    return path
  end

  local real = vim.loop.fs_realpath(path)
  local normalized = real or path
  normalized = normalized:gsub("/+$", "")
  if normalized == "" then
    return "/"
  end
  return normalized
end

local function starts_with(value, prefix)
  return value:sub(1, #prefix) == prefix
end

local function trim(value)
  return value:match("^%s*(.-)%s*$")
end

local function strip_jsonc(raw)
  local stripped = raw:gsub("/%*.-%*/", "")
  stripped = stripped:gsub("(^%s*//[^\n]*\n)", "")
  stripped = stripped:gsub("\n%s*//[^\n]*", "\n")
  stripped = stripped:gsub(",%s*([}%]])", "%1")
  return stripped
end

local function decode_jsonc(path)
  local lines = vim.fn.readfile(path)
  local raw = table.concat(lines, "\n")

  local ok_raw, parsed_raw = pcall(vim.json.decode, raw)
  if ok_raw and type(parsed_raw) == "table" then
    return parsed_raw
  end

  local sanitized = strip_jsonc(raw)
  local ok, parsed = pcall(vim.json.decode, sanitized)
  if ok and type(parsed) == "table" then
    return parsed
  end

  return nil
end

local function resolve_template_path(template, host_workspace)
  if type(template) ~= "string" or template == "" then
    return nil
  end

  local basename = vim.fn.fnamemodify(host_workspace, ":t")
  local resolved = template
  resolved = resolved:gsub("%${localWorkspaceFolderBasename}", basename)
  resolved = resolved:gsub("%${localWorkspaceFolder}", host_workspace)

  if resolved:find("%${", 1, true) then
    return nil
  end

  if not starts_with(resolved, "/") then
    resolved = host_workspace .. "/" .. resolved
  end

  return normalize(resolved)
end

local function parse_workspace_mount_target(workspace_mount)
  if type(workspace_mount) ~= "string" or workspace_mount == "" then
    return nil
  end

  for part in workspace_mount:gmatch("[^,]+") do
    local key, value = part:match("^%s*([^=]+)=(.+)%s*$")
    if key and value then
      key = trim(key)
      value = trim(value)
      if key == "target" or key == "dst" or key == "destination" then
        return value
      end
    end
  end

  return nil
end

local function resolve_container_workspace(host_workspace, opts)
  if opts and type(opts.container_workspace_folder) == "string" and opts.container_workspace_folder ~= "" then
    return normalize(opts.container_workspace_folder)
  end

  local has_dc, dc_path = detection.has_devcontainer(host_workspace)
  if not has_dc or not dc_path then
    return nil
  end

  local config = decode_jsonc(dc_path)
  if not config then
    return nil
  end

  local from_workspace_folder = resolve_template_path(config.workspaceFolder, host_workspace)
  if from_workspace_folder then
    return from_workspace_folder
  end

  local mount_target = parse_workspace_mount_target(config.workspaceMount)
  local from_workspace_mount = resolve_template_path(mount_target, host_workspace)
  if from_workspace_mount then
    return from_workspace_mount
  end

  local default_workspace = resolve_template_path("/workspaces/${localWorkspaceFolderBasename}", host_workspace)
  if default_workspace then
    return default_workspace
  end

  if type(config.workspaceFolder) == "string" and config.workspaceFolder ~= "" then
    utils.log("debug", "Could not fully resolve workspaceFolder in devcontainer.json: " .. config.workspaceFolder)
  end

  return nil
end

function M.create_mapper(host_workspace, opts)
  local root_workspace = detection.find_workspace_root(host_workspace or vim.fn.getcwd())
  local normalized_host = normalize(root_workspace)
  local container_workspace = resolve_container_workspace(normalized_host, opts) or normalized_host

  local mapper = {}

  function mapper.map_path(path)
    if type(path) ~= "string" or path == "" then
      return path
    end

    if not path_exists(path) then
      return path
    end

    local normalized_path = normalize(path)
    if normalized_path == normalized_host then
      return container_workspace
    end

    local host_prefix = normalized_host .. "/"
    if starts_with(normalized_path, host_prefix) then
      return container_workspace .. normalized_path:sub(#normalized_host + 1)
    end

    return path
  end

  function mapper.map_path_to_host(path)
    if type(path) ~= "string" or path == "" then
      return path
    end

    local normalized_path = normalize(path)
    if normalized_path == container_workspace then
      return normalized_host
    end

    local container_prefix = container_workspace .. "/"
    if starts_with(normalized_path, container_prefix) then
      return normalized_host .. normalized_path:sub(#container_workspace + 1)
    end

    return path
  end

  function mapper.map_string(value)
    if type(value) ~= "string" or value == "" then
      return value
    end

    if starts_with(value, "file://") then
      local ok, fname = pcall(vim.uri_to_fname, value)
      if ok and fname then
        local mapped = mapper.map_path(fname)
        if mapped ~= fname then
          return vim.uri_from_fname(mapped)
        end
      end
      return value
    end

    if starts_with(value, "/") then
      return mapper.map_path(value)
    end

    return value
  end

  function mapper.map_string_to_host(value)
    if type(value) ~= "string" or value == "" then
      return value
    end

    if starts_with(value, "file://") then
      local ok, fname = pcall(vim.uri_to_fname, value)
      if ok and fname then
        local mapped = mapper.map_path_to_host(fname)
        if mapped ~= fname then
          return vim.uri_from_fname(mapped)
        end
      end
      return value
    end

    if starts_with(value, "/") then
      return mapper.map_path_to_host(value)
    end

    return value
  end

  function mapper.map_table_in_place(value, seen)
    if type(value) ~= "table" then
      return value
    end

    function mapper.map_table_to_host_in_place(value, seen)
      if type(value) ~= "table" then
        return value
      end

      seen = seen or {}
      if seen[value] then
        return value
      end
      seen[value] = true

      for key, item in pairs(value) do
        if type(item) == "string" then
          value[key] = mapper.map_string_to_host(item)
        elseif type(item) == "table" then
          mapper.map_table_to_host_in_place(item, seen)
        end
      end

      return value
    end

    seen = seen or {}
    if seen[value] then
      return value
    end
    seen[value] = true

    for key, item in pairs(value) do
      if type(item) == "string" then
        value[key] = mapper.map_string(item)
      elseif type(item) == "table" then
        mapper.map_table_in_place(item, seen)
      end
    end

    return value
  end

  function mapper.map_cmd(cmd)
    if type(cmd) ~= "table" then
      return cmd
    end

    local mapped = {}
    for i, arg in ipairs(cmd) do
      if type(arg) == "string" then
        mapped[i] = mapper.map_string(arg)
      else
        mapped[i] = arg
      end
    end
    return mapped
  end

  return mapper
end

return M
