local lifecycle = require("devcontainer.cli.lifecycle")
local exec = require("devcontainer.cli.exec")
local utils = require("devcontainer.utils")

return {
  setup = utils.set_config,
  get_config = utils.get_config,
  up = lifecycle.up,
  build = lifecycle.build,
  restart = lifecycle.restart,
  exec = exec.exec,
  wrap_cmd = exec.wrap_cmd,
}
