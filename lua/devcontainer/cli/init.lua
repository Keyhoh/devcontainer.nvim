local lifecycle = require("devcontainer.cli.lifecycle")
local exec = require("devcontainer.cli.exec")

return {
  up = lifecycle.up,
  build = lifecycle.build,
  restart = lifecycle.restart,
  exec = exec.exec,
}
