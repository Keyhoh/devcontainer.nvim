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
The plugin provides the following user commands:

- `:DevcontainerUp` - Start the Dev Container for the current workspace.
- `:DevcontainerExec {cmd}` - Execute a command inside the Dev Container in an interactive terminal.

Examples:
```vim
:DevcontainerUp
:DevcontainerExec bash
:DevcontainerExec psql -h localhost
```

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

(Generated: 2026-09-27)
