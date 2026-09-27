local devcontainer = require('devcontainer.lsp')

describe('wrap_cmd', function()
  it('wraps simple command', function()
    local wrapped = devcontainer.wrap_cmd({ 'gopls' }, '/project')
    assert.are.same({ 'devcontainer', 'exec', '--workspace-folder', '/project', 'gopls' }, wrapped)
  end)

  it('preserves args', function()
    local wrapped = devcontainer.wrap_cmd({ 'typescript-language-server', '--stdio' }, '/project')
    assert.are.same({ 'devcontainer', 'exec', '--workspace-folder', '/project', 'typescript-language-server', '--stdio' }, wrapped)
  end)

  it('does not mutate original', function()
    local orig = { 'gopls' }
    local _ = devcontainer.wrap_cmd(orig, '/project')
    assert.are.same({ 'gopls' }, orig)
  end)
end)
