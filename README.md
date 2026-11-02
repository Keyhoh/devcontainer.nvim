# devcontainer.nvim

A Neovim plugin that runs Language Servers inside a Dev Container while Neovim continues to run on the host.

Overview
- The plugin wraps language server start commands with `devcontainer exec`, preserving stdin/stdout so LSP communication remains unchanged.

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

LSP Integration
The plugin automatically wraps LSP commands to run inside the Dev Container. When a Dev Container is detected, language servers are transparently executed via `devcontainer exec`.

Example configuration with LSP wrapping:

```lua
require('devcontainer').setup()

-- Configuration example: Go (gopls)
local devcontainer = require('devcontainer')

vim.lsp.config('gopls', {
  cmd = devcontainer.wrap_lsp_cmd({ 'gopls' }),
})

-- Or use wrap_for_lsp to apply wrapping to an entire config
vim.lsp.config('tsserver', devcontainer.wrap_for_lsp({
  cmd = { 'typescript-language-server', '--stdio' },
  name = 'tsserver',
}))

vim.lsp.enable('gopls')
vim.lsp.enable('tsserver')
```

API Reference
- `wrap_lsp_cmd(cmd, workspace)` - Wraps an LSP command array for execution in the Dev Container. Returns the wrapped command array.
- `wrap_for_lsp(config, workspace)` - Wraps an entire LSP config table. Returns a new config with the wrapped command.

Manual verification (minimal)
- Add a `.devcontainer/devcontainer.json` to a project.
- Start the container: `:DevcontainerUp`
- Execute commands in the container: `:DevcontainerExec bash`
- When LSP support is implemented, open a file and verify the LSP starts via `devcontainer exec` and that completion/diagnostics work.

Development and testing
- Implementation lives under `lua/devcontainer/` (init.lua, detection.lua, cli.lua, lsp.lua).
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

