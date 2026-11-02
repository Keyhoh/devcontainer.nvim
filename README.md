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

- `:Devcontainer up` - Start the Dev Container for the current workspace.
- `:Devcontainer exec {cmd}` - Execute a command inside the Dev Container in an interactive terminal.
- `:Devcontainer build` - Build the Dev Container image.
- `:Devcontainer restart` - Restart the Dev Container (stop and start).
- `:Devcontainer restart --build|-b` - Rebuild and restart the Dev Container.

Examples:
```vim
:Devcontainer up
:Devcontainer exec bash
:Devcontainer exec psql -h localhost
:Devcontainer build
:Devcontainer restart
:Devcontainer restart --build
:Devcontainer restart -b
```

Command Wrapping
The plugin provides functions to wrap arbitrary commands for execution inside a Dev Container. When a Dev Container is detected, commands are transparently executed via `devcontainer exec`.

### General Command Wrapping

Use `wrap_cmd()` to wrap any command array:

```lua
require('devcontainer').setup()

local devcontainer = require('devcontainer')

-- Wrap an arbitrary command
local wrapped = devcontainer.wrap_cmd({ 'node', 'server.js' })
-- If Dev Container exists: ['devcontainer', 'exec', '--workspace-folder', '...', 'node', 'server.js']
-- Otherwise: ['node', 'server.js'] (unchanged)
```

### LSP Integration

### LSP Integration

For LSP configuration, use `wrap_cmd()` directly or `wrap_for_lsp()` for wrapping entire configs:

```lua
require('devcontainer').setup()

local devcontainer = require('devcontainer')

-- Wrap an LSP command directly
vim.lsp.config('gopls', {
  cmd = devcontainer.wrap_cmd({ 'gopls' }),
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
- `wrap_cmd(cmd, workspace)` - Wraps a command array for execution in the Dev Container. Returns the wrapped command array or the original if no Dev Container is found.
  - `cmd` (table): Command array (e.g., `{ 'gopls' }`, `{ 'node', 'server.js' }`)
  - `workspace` (string, optional): Workspace path (defaults to current directory)

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
  - Example single busted test: `busted spec/command_spec.lua --pattern "wrap_cmd"`
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

