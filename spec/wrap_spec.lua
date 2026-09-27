describe('wrap_lsp integration', function()
  it('calls lspconfig.setup with wrapped cmd when devcontainer detected', function()
    -- stub detection
    package.loaded['devcontainer.detection'] = { find_workspace_root = function() return '/project' end }
    package.loaded['devcontainer.lsp'] = { wrap_cmd = function(cmd, ws) return { 'devcontainer', 'exec', '--workspace-folder', ws, unpack(cmd) } end }

    -- fake cli.up to immediately invoke callback
    package.loaded['devcontainer.cli'] = { up = function(ws, cb) if cb then cb(0, 0) end return {} end }

    -- fake lspconfig
    local called = false
    local fake = {}
    fake['gopls'] = { setup = function(cfg) called = true; assert.are.same({ 'devcontainer', 'exec', '--workspace-folder', '/project', 'gopls' }, cfg.cmd) end }
    package.loaded['lspconfig'] = fake

    local devcontainer = require('devcontainer')
    devcontainer.wrap_lsp('gopls', { cmd = { 'gopls' } })
    assert.is_true(called)

    -- cleanup
    package.loaded['devcontainer.detection'] = nil
    package.loaded['devcontainer.lsp'] = nil
    package.loaded['devcontainer.cli'] = nil
    package.loaded['lspconfig'] = nil
  end)
end)
