# Managed in https://github.com/coder/templates

##
# Desktop IDEs
##

module "vscode" {
  count   = data.coder_workspace.me.start_count
  source  = "registry.coder.com/coder/vscode-desktop/coder"
  version = "1.1.1"

  group = "Desktop IDEs"
  order = 1

  agent_id = coder_agent.pod-agent.id
}

module "cursor" {
  count   = data.coder_workspace.me.start_count
  source  = "registry.coder.com/coder/cursor/coder"
  version = "1.2.1"

  group = "Desktop IDEs"
  order = 4

  agent_id = coder_agent.pod-agent.id
}

module "windsurf" {
  count   = data.coder_workspace.me.start_count
  source  = "registry.coder.com/coder/windsurf/coder"
  version = "1.1.1"

  group = "Desktop IDEs"
  order = 5

  agent_id = coder_agent.pod-agent.id
}

module "kiro" {
  count   = data.coder_workspace.me.start_count
  source  = "registry.coder.com/coder/kiro/coder"
  version = "1.0.0"

  group = "Desktop IDEs"
  order = 6

  agent_id = coder_agent.pod-agent.id
}

module "zed" {
  count   = data.coder_workspace.me.start_count
  source  = "registry.coder.com/coder/zed/coder"
  version = "1.0.1"

  group = "Desktop IDEs"
  order = 7

  agent_id = coder_agent.pod-agent.id
}

###
# Web IDEs
###

module "code-server" {
  count   = data.coder_workspace.me.start_count
  source  = "registry.coder.com/coder/code-server/coder"
  version = "1.3.1"

  group = "Web IDEs"
  order = 8

  agent_id = coder_agent.pod-agent.id
}

module "vscode-web" {
  count          = data.coder_workspace.me.start_count
  accept_license = true
  extensions     = ["github.copilot", "ms-python.python", "ms-toolsai.jupyter", "redhat.vscode-yaml"]

  source  = "registry.coder.com/coder/vscode-web/coder"
  version = "1.3.1"

  group = "Web IDEs"
  order = 9

  agent_id = coder_agent.pod-agent.id
}

data "coder_parameter" "jupyter" {
  name        = "Jupyter IDE type"
  type        = "string"
  description = "What type of Jupyter do you want?"
  mutable     = true
  default     = ""
  form_type   = "dropdown"
  icon        = "/icon/jupyter.svg"
  order       = 999

  option {
    name  = "Jupyter Lab"
    value = "lab"
    icon  = "https://raw.githubusercontent.com/gist/egormkn/672764e7ce3bdaf549b62a5e70eece79/raw/559e34c690ea4765001d4ba0e715106edea7439f/jupyter-lab.svg"
  }
  option {
    name  = "Jupyter Notebook"
    value = "notebook"
    icon  = "https://codingbootcamps.io/wp-content/uploads/jupyter_notebook.png"
  }
  option {
    name  = "None"
    value = ""
  }
}

locals {
  use_notebook = data.coder_parameter.jupyter.value == "notebook" ? 1 : 0
  use_lab_only = data.coder_parameter.jupyter.value == "lab" ? 1 : 0
}

module "jupyterlab" {
  count = local.use_notebook * data.coder_workspace.me.start_count

  source  = "registry.coder.com/coder/jupyterlab/coder"
  version = "1.1.1"

  group = "Web IDEs"
  order = 11

  agent_id = coder_agent.pod-agent.id
}

module "jupyterlab-notebook" {
  count = local.use_lab_only * data.coder_workspace.me.start_count

  source  = "registry.coder.com/coder/jupyter-notebook/coder"
  version = "1.2.0"

  group = "Web IDEs"
  order = 12

  agent_id = coder_agent.pod-agent.id
}

##
# Jetbrains
##

module "jetbrains" {
  count = data.coder_workspace.me.start_count

  source   = "registry.coder.com/coder/jetbrains/coder"
  version  = "1.1.1"

  folder                = local.home_dir
  group                 = "JetBrains IDEs"
  coder_app_order       = 13
  coder_parameter_order = 10

  # tooltip  = "You need to [Install Coder Desktop](https://coder.com/docs/user-guides/desktop#install-coder-desktop) to use this button."  # Optional

  agent_name = "pod-agent"
  agent_id   = coder_agent.pod-agent.id
}

module "filebrowser" {
  count = data.coder_workspace.me.start_count

  source  = "registry.coder.com/coder/filebrowser/coder"
  version = "1.1.2"

  order = 14

  agent_id = coder_agent.pod-agent.id
}