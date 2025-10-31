# Managed in https://github.com/coder/templates
module "dotfiles" {
  source  = "registry.coder.com/coder/dotfiles/coder"
  version = "1.2.1"

  agent_id = coder_agent.pod-agent.id
  count    = data.coder_workspace.me.start_count
}

module "coder-login" {
  source  = "registry.coder.com/coder/coder-login/coder"
  version = "1.0.31"

  agent_id = coder_agent.pod-agent.id
  count    = data.coder_workspace.me.start_count
}