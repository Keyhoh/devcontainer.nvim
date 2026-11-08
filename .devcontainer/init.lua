-- Dev Container-specific Neovim configuration for devcontainer.nvim project

-- Wrap LSP commands to run inside the Dev Container
local devcontainer = require('devcontainer')

-- Configure Lua Language Server (lua-language-server)
-- The server should be available in the Dev Container
vim.lsp.config('lua_ls', devcontainer.wrap_for_lsp({
  cmd = { 'lua-language-server' },
  root_markers = { '.luarc.json', '.git' },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = { 'vim' },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false,
      },
    },
  },
}))

vim.lsp.enable('lua_ls')
