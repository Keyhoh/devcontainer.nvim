local init = require('devcontainer')

describe('wrap_lsp_config', function()
  it('wraps cmd when workspace provided', function()
    local cfg = { cmd = { 'gopls' } }
    local wrapped = init.wrap_lsp_config(cfg, '/project')
    assert.are.same({ 'devcontainer', 'exec', '--workspace-folder', '/project', 'gopls' }, wrapped.cmd)
  end)

  it('returns original if no cmd', function()
    local cfg = { settings = {} }
    assert.are.same(cfg, init.wrap_lsp_config(cfg, '/project'))
  end)
end)
