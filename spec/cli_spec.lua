local cli = require('devcontainer.cli')

describe('cli arg builders', function()
  it('builds up args', function()
    assert.are.same({ 'devcontainer', 'up', '--workspace-folder', '/project' }, cli.up_args('/project'))
  end)

  it('builds exec args', function()
    assert.are.same({ 'devcontainer', 'exec', '--workspace-folder', '/project', 'gopls' }, cli.exec_args('/project', { 'gopls' }))
  end)
end)
