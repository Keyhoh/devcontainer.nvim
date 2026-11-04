# devcontainer.nvim

A Neovim plugin that runs commands inside a Dev Container while Neovim continues to run on the host.

Overview
- The plugin wraps command start commands with `devcontainer exec`, preserving stdin/stdout so communication remains unchanged.
- Particularly useful for language servers and other long-running processes.

Quickstart
1. Install the `devcontainer` CLI.
2. Install the plugin using your plugin manager.
3. Enable the plugin in your Neovim config:

```lua
require('devcontainer').setup()
```

Commands
The plugin provides the following user command:

- `:Devcontainer up` - Start the Dev Container for the current workspace (default: async/background).
- `:Devcontainer up --sync` - Start the Dev Container synchronously (blocks until complete).
- `:Devcontainer exec {cmd}` - Execute a command inside the Dev Container in an interactive terminal.
- `:Devcontainer build` - Build the Dev Container image (default: async/background).
- `:Devcontainer build --sync` - Build the Dev Container synchronously.
- `:Devcontainer restart` - Restart the Dev Container (default: async/background).
- `:Devcontainer restart --sync` - Restart synchronously.
- `:Devcontainer restart --build|-b` - Rebuild and restart the Dev Container (async by default).
- `:Devcontainer restart --build --sync` - Rebuild and restart synchronously.

Examples:
```vim
:Devcontainer up
:Devcontainer up --sync
:Devcontainer exec bash
:Devcontainer exec psql -h localhost
:Devcontainer build
:Devcontainer build --sync
:Devcontainer restart
:Devcontainer restart --build
:Devcontainer restart --build --sync
```

**Background Execution and Logging**

By default, `:Devcontainer up`, `:Devcontainer build`, and `:Devcontainer restart` run asynchronously in the background, allowing Neovim to remain responsive.

**Note:** When LSP or other tools call `exec_cmd()`, the container is started synchronously to ensure immediate availability. This guarantees LSP functionality while keeping user-initiated commands responsive.

To see operation progress, configure logging level:

```lua
require('devcontainer').setup({
  log_level = 'debug',  -- Shows detailed logs including command output
})
```

Log levels:
- `'error'` - Only errors (default)
- `'info'` - Errors and status messages
- `'debug'` - Errors, status, and detailed command output

Logs are sent to Neovim's built-in notify system and appear in `:messages` history. When an operation is running, you'll see a notification confirming it started.

Command Wrapping
The plugin provides functions to wrap arbitrary commands for execution inside a Dev Container. When a Dev Container is detected, commands are transparently executed via `devcontainer exec`.

### General Command Wrapping

Use `exec_cmd()` to wrap any command array:

```lua
require('devcontainer').setup()

local devcontainer = require('devcontainer')

-- Wrap an arbitrary command (synchronous: waits for container to start)
local wrapped = devcontainer.exec_cmd({ 'node', 'server.js' })
-- If Dev Container exists: ['devcontainer', 'exec', '--workspace-folder', '...', 'node', 'server.js']
-- Otherwise: ['node', 'server.js'] (unchanged)

-- Wrap with async container startup (returns immediately)
local wrapped_async = devcontainer.exec_cmd({ 'node', 'server.js' }, nil, { async = true })
```

**Options:**
- `async` (boolean, optional): Start the container asynchronously. Default is `false` (blocks until container is ready).
  - `false` (default): Ensures container is ready before returning; use for LSP and critical services.
  - `true`: Starts container in background; use for non-critical tools or when responsiveness is preferred.

### LSP Integration

### LSP Integration

For LSP configuration, use `exec_cmd()` directly or `wrap_for_lsp()` for wrapping entire configs:

```lua
require('devcontainer').setup()

local devcontainer = require('devcontainer')

-- Wrap an LSP command directly
vim.lsp.config('gopls', {
  cmd = devcontainer.exec_cmd({ 'gopls' }),
})

-- Or wrap an entire LSP config
vim.lsp.config('tsserver', devcontainer.wrap_for_lsp({
  cmd = { 'typescript-language-server', '--stdio' },
  name = 'tsserver',
}))

vim.lsp.enable('gopls')
vim.lsp.enable('tsserver')
```

API Reference

**Command Wrapping:**
- `exec_cmd(cmd, workspace, opts)` - Wraps a command array for execution in the Dev Container via `devcontainer exec`. Returns the wrapped command array or the original if no Dev Container is found.
  - `cmd` (table): Command array (e.g., `{ 'gopls' }`, `{ 'node', 'server.js' }`)
  - `workspace` (string, optional): Workspace path (defaults to current directory)
  - `opts` (table, optional): Options table
    - `async` (boolean): If `true`, starts container asynchronously. Default: `false`
- `create_exec_wrapper(workspace, opts)` - Creates a reusable wrapper function for the given workspace.
  - `workspace` (string, optional): Workspace path (defaults to current directory)
  - `opts` (table, optional): Options table
  - Returns a function that accepts a command array and returns the wrapped command

**LSP Configuration (convenience wrappers):**
- `wrap_for_lsp(config, workspace)` - Wraps an entire LSP config table. Returns a new config with the wrapped command.

Manual verification (minimal)
- Add a `.devcontainer/devcontainer.json` to a project.
- Start the container: `:Devcontainer up`
- Execute commands in the container: `:Devcontainer exec bash`
- When LSP support is implemented, open a file and verify the LSP starts via `devcontainer exec` and that completion/diagnostics work.

Development and testing
- Implementation lives under `lua/devcontainer/` with modular structure:
  - Core modules: `init.lua`, `utils.lua`, `detection.lua`, `cmd_wrapper.lua`
  - CLI subcommands: `cli/` directory
- Unit tests: use busted or plenary.nvim.
  - Example single busted test: `busted spec/command_spec.lua --pattern "exec_cmd"`
- Integration testing: manual verification with a minimal Dev Container that includes the language server binary.

Configuration example
```lua
require('devcontainer').setup({
  auto_start = true,
  log_level = 'error',
})
```

Specification and agent guidance
- Implementation requirements and design are in `SPECIFICATION.md`.
- Agent guidance for automation is in `AGENTS.md`.

Contributing
- Open an issue to discuss major changes. Include tests and documentation with pull requests.

