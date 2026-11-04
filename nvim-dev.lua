-- Devcontainer.nvim Test Configuration
-- Usage: nvim -u nvim-dev.lua
-- 
-- Commands to test:
--   :DevcontainerUp         - Start the Dev Container
--   :DevcontainerExec bash  - Open interactive bash in container
--   :TestLspWrap            - Test LSP command wrapping

vim.opt.rtp:prepend("~/Groups/Personal/Workspaces/devcontainer.nvim")
require("devcontainer").setup({
  log_level = "debug",
})

-- LSP Configuration with Dev Container wrapping
local devcontainer = require("devcontainer")

-- Example: Go (gopls)
vim.lsp.config("gopls", {
  cmd = devcontainer.exec_cmd({ "gopls" }),
  root_markers = { "go.mod", ".git" },
})

-- Example: TypeScript (typescript-language-server)
vim.lsp.config("tsserver", {
  cmd = devcontainer.exec_cmd({ "typescript-language-server", "--stdio" }),
  root_markers = { "package.json", ".git" },
})

-- Example: Lua (lua-language-server)
vim.lsp.config("lua_ls", {
  cmd = devcontainer.exec_cmd({ "lua-language-server" }),
  root_markers = { ".luarc.json", ".git" },
})

-- Enable LSP clients (uncomment as needed for testing)
-- vim.lsp.enable("gopls")
-- vim.lsp.enable("tsserver")
-- vim.lsp.enable("lua_ls")

-- Debug command to test wrapping
vim.api.nvim_create_user_command("TestLspWrap", function()
  local devcontainer = require("devcontainer")
  local wrapped = devcontainer.exec_cmd({ "gopls" }, vim.fn.getcwd())
  vim.notify("Wrapped command: " .. table.concat(wrapped, " "), vim.log.levels.INFO)
end, {
  desc = "Test LSP command wrapping",
})

-- Startup message
vim.notify("devcontainer.nvim loaded - Use :TestLspWrap to test LSP wrapping", vim.log.levels.INFO)
