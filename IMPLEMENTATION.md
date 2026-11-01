# LSP Wrapping Implementation

## Overview

The LSP wrapping feature automatically detects Dev Containers and wraps language server commands to execute inside the container while preserving stdin/stdout for Neovim LSP communication.

## Architecture

### Module Responsibilities

#### `lua/devcontainer/detection.lua`
- Detects Dev Container presence in a workspace
- Searches for `.devcontainer/devcontainer.json` or `.devcontainer.json`
- Provides workspace root detection using `.git` or devcontainer markers

**Key Functions:**
- `has_devcontainer(workspace)` - Returns (bool, path) indicating if a Dev Container exists
- `find_workspace_root(path)` - Finds the workspace root from a given path

#### `lua/devcontainer/cli.lua`
- Thin wrapper around the official Dev Container CLI
- Manages Dev Container lifecycle (up, exec)
- Handles configuration and logging

**Key Functions:**
- `up()` - Starts the Dev Container
- `exec(cmd)` - Wraps a command with `devcontainer exec`
- `wrap_cmd(cmd)` - Alias for exec

#### `lua/devcontainer/lsp.lua`
- Core LSP wrapping logic
- Detects Dev Containers and ensures they're running
- Wraps LSP commands transparently

**Key Functions:**
- `wrap_lsp_cmd(cmd, workspace)` - Wraps an LSP command array
- `create_lsp_wrapper(workspace)` - Returns a wrapper function for a specific workspace

#### `lua/devcontainer/init.lua`
- Public API and user-facing functions
- Vim commands registration
- Helper functions for Neovim LSP integration

**Key Functions:**
- `setup(opts)` - Initialize plugin
- `wrap_lsp_cmd(cmd, workspace)` - Public wrapper function
- `wrap_for_lsp(config, workspace)` - Wraps entire LSP configuration

## How It Works

1. **Detection Phase**
   - When `wrap_lsp_cmd` is called, `detection.lua` checks if a Dev Container exists
   - If no Dev Container is found, the original command is returned unchanged
   - If one is found, the wrapping process continues

2. **Container Start Phase**
   - `lsp.lua` calls `cli.up()` to ensure the Dev Container is running
   - The `started_containers` cache prevents redundant starts
   - If startup fails, wrapping is aborted

3. **Command Wrapping Phase**
   - Original command array is preserved (not modified)
   - New array is created: `["devcontainer", "exec", "--workspace-folder", <path>, ...cmd]`
   - All original command arguments are appended intact

4. **Execution Phase**
   - Neovim LSP client receives the wrapped command
   - Calls it like any other process
   - stdin/stdout are preserved through the wrapper
   - LSP protocol messages flow unchanged

## Design Constraints Met

✅ stdin/stdout preserved - LSP communication unmodified
✅ Original commands not mutated - Safe to call multiple times
✅ Transparent wrapping - Existing Neovim configs work
✅ argv style arrays - Avoids shell quoting issues
✅ Proper logging - Debug info in Neovim notifications
✅ Container caching - No redundant starts
✅ Clean separation - Modular architecture

## Usage Examples

### Basic LSP Configuration

```lua
require('devcontainer').setup()

vim.lsp.config('gopls', {
  cmd = require('devcontainer').wrap_lsp_cmd({ 'gopls' }),
})

vim.lsp.enable('gopls')
```

### Programmatic Wrapping

```lua
local devcontainer = require('devcontainer')

-- Wrap a single command
local wrapped = devcontainer.wrap_lsp_cmd({ 'gopls' }, '/path/to/project')

-- Wrap an entire LSP config
local config = devcontainer.wrap_for_lsp({
  cmd = { 'typescript-language-server', '--stdio' },
  name = 'tsserver',
}, '/path/to/project')
```

## Testing

The implementation has been tested for:
- ✅ Command wrapping correctness
- ✅ Multiple argument preservation
- ✅ Original array immutability
- ✅ Dev Container detection
- ✅ Config wrapping

Integration testing should verify:
1. Dev Container starts automatically
2. LSP connects through `devcontainer exec`
3. Diagnostics/completion/navigation work
4. LSP stdout is not corrupted
