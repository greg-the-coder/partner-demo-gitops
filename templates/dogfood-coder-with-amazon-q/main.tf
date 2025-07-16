terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "2.5.2"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

data "coder_workspace_preset" "goland_us" {
  name = "GoLand US"
  parameters = {
    "jetbrains_ide" = "GO"
    "Region" = "us-pittsburgh"
  }
}

data "coder_workspace_preset" "goland_eu" {
  name = "GoLand EU"
  parameters = {
    "jetbrains_ide" = "GO"
    "Region" = "eu-helsinki"
  }
}

data "coder_workspace_preset" "goland_ap" {
  name = "GoLand AP"
  parameters = {
    "jetbrains_ide" = "GO"
    "Region" = "ap-sydney"
  }
}

data "coder_workspace_preset" "goland_sa" {
  name = "GoLand SA"
  parameters = {
    "jetbrains_ide" = "GO"
    "Region" = "sa-saopaulo"
  }
}

data "coder_workspace_preset" "goland_za" {
  name = "GoLand ZA"
  parameters = {
    "jetbrains_ide" = "GO"
    "Region" = "za-cpt"
  }
}

data "coder_parameter" "ai_prompt" {
  type        = "string"
  name        = "AI Prompt"
  description = "Write a prompt for Amazon Q"
  mutable     = true
}

variable "amazon_q_auth_tarball" {
  type        = string
  description = "Base64 encoded, zstd compressed tarball of a pre-authenticated ~/.local/share/amazon-q directory. After running `q login` on another machine, you may generate it with: `cd ~/.local/share/amazon-q && tar -c . | zstd | base64 -w 0`"
  validation {
    condition     = length(var.amazon_q_auth_tarball) > 0
    error_message = "The amazon_q_auth_tarball variable must be provided and cannot be empty."
  }
}

module "amazon-q" {
  source              = "./modules/amazon-q"
  agent_id            = coder_agent.dev.id
  folder              = "/home/coder/coder"
  install_amazon_q = true

  # TODO: put the icon in a CDN Coder controls
  icon                = "https://downloads.marketplace.jetbrains.com/files/24267/727961/icon/default.png"
  # Enable experimental features
  experiment_use_tmux          = true
  experiment_report_tasks       = true
  experiment_auth_tarball = var.amazon_q_auth_tarball
}

locals {
  // These are cluster service addresses mapped to Tailscale nodes. Ask Dean or
  // Kyle for help.
  docker_host = {
    ""              = "tcp://dogfood-ts-cdr-dev.tailscale.svc.cluster.local:2375"
    "us-pittsburgh" = "tcp://dogfood-ts-cdr-dev.tailscale.svc.cluster.local:2375"
    // For legacy reasons, this host is labelled `eu-helsinki` but it's
    // actually in Germany now.
    "eu-helsinki" = "tcp://katerose-fsn-cdr-dev.tailscale.svc.cluster.local:2375"
    "ap-sydney"   = "tcp://wolfgang-syd-cdr-dev.tailscale.svc.cluster.local:2375"
    "sa-saopaulo" = "tcp://oberstein-sao-cdr-dev.tailscale.svc.cluster.local:2375"
    "za-cpt"      = "tcp://schonkopf-cpt-cdr-dev.tailscale.svc.cluster.local:2375"
  }

  repo_base_dir  = "~"
  repo_dir       = "/home/coder/coder"
  container_name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
}

data "coder_parameter" "region" {
  type    = "string"
  name    = "Region"
  icon    = "/emojis/1f30e.png"
  default = "us-pittsburgh"
  option {
    icon  = "/emojis/1f1fa-1f1f8.png"
    name  = "Pittsburgh"
    value = "us-pittsburgh"
  }
  option {
    icon = "/emojis/1f1e9-1f1ea.png"
    name = "Falkenstein"
    // For legacy reasons, this host is labelled `eu-helsinki` but it's
    // actually in Germany now.
    value = "eu-helsinki"
  }
  option {
    icon  = "/emojis/1f1e6-1f1fa.png"
    name  = "Sydney"
    value = "ap-sydney"
  }
  option {
    icon  = "/emojis/1f1e7-1f1f7.png"
    name  = "São Paulo"
    value = "sa-saopaulo"
  }
  option {
    icon  = "/emojis/1f1ff-1f1e6.png"
    name  = "Cape Town"
    value = "za-cpt"
  }
}

provider "docker" {
  host = lookup(local.docker_host, data.coder_parameter.region.value)
}

provider "coder" {}

data "coder_external_auth" "github" {
  id = "github"
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}
data "coder_workspace_tags" "tags" {
  tags = {
    "cluster" : "dogfood-v2"
    "env" : "gke"
  }
}

module "git-config" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/git-config/coder"
  version  = "1.0.15"
  agent_id = coder_agent.dev.id
}

module "slackme" {
  count            = data.coder_workspace.me.start_count
  source           = "dev.registry.coder.com/modules/slackme/coder"
  version          = ">= 1.0.0"
  agent_id         = coder_agent.dev.id
  auth_provider_id = "slack"
}

module "dotfiles" {
  count    = data.coder_workspace.me.start_count
  source   = "dev.registry.coder.com/modules/dotfiles/coder"
  version  = ">= 1.0.0"
  agent_id = coder_agent.dev.id
}

module "git-clone" {
  count    = data.coder_workspace.me.start_count
  source   = "dev.registry.coder.com/modules/git-clone/coder"
  version  = "1.0.18"
  agent_id = coder_agent.dev.id
  url      = "https://github.com/coder/coder"
  base_dir = local.repo_base_dir
}

module "personalize" {
  count    = data.coder_workspace.me.start_count
  source   = "dev.registry.coder.com/modules/personalize/coder"
  version  = ">= 1.0.0"
  agent_id = coder_agent.dev.id
}

module "code-server" {
  count                   = data.coder_workspace.me.start_count
  source                  = "dev.registry.coder.com/modules/code-server/coder"
  version                 = ">= 1.0.0"
  agent_id                = coder_agent.dev.id
  folder                  = local.repo_dir
  auto_install_extensions = true
}

module "vscode-web" {
  count                   = data.coder_workspace.me.start_count
  source                  = "registry.coder.com/modules/vscode-web/coder"
  version                 = ">= 1.0.0"
  agent_id                = coder_agent.dev.id
  folder                  = local.repo_dir
  extensions              = ["github.copilot"]
  auto_install_extensions = true # will install extensions from the repos .vscode/extensions.json file
  accept_license          = true
}

module "jetbrains_gateway" {
  count          = data.coder_workspace.me.start_count
  source         = "dev.registry.coder.com/modules/jetbrains-gateway/coder"
  version        = ">= 1.0.0"
  agent_id       = coder_agent.dev.id
  agent_name     = "dev"
  folder         = local.repo_dir
  jetbrains_ides = ["GO", "WS"]
  default        = "GO"
  latest         = true
}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "dev.registry.coder.com/modules/coder-login/coder"
  version  = ">= 1.0.0"
  agent_id = coder_agent.dev.id
}

module "cursor" {
  count    = data.coder_workspace.me.start_count
  source   = "dev.registry.coder.com/modules/cursor/coder"
  version  = ">= 1.0.0"
  agent_id = coder_agent.dev.id
  folder   = local.repo_dir
}

module "zed" {
  count    = data.coder_workspace.me.start_count
  source   = "./zed"
  agent_id = coder_agent.dev.id
  folder   = local.repo_dir
}

resource "coder_agent" "dev" {
  arch = "amd64"
  os   = "linux"
  dir  = local.repo_dir
  env = {
    OIDC_TOKEN                          = data.coder_workspace_owner.me.oidc_access_token,
    CODER_MCP_AMAZON_Q_TASK_PROMPT      = data.coder_parameter.ai_prompt.value,
    CODER_MCP_AMAZON_Q_SYSTEM_PROMPT    = <<-EOT
    You are a helpful Coding assistant. Aim to autonomously investigate
    and solve issues the user gives you and test your work, whenever possible.
    Avoid shortcuts like mocking tests. When you get stuck, you can ask the user
    but opt for autonomy.

    YOU MUST REPORT ALL TASKS TO CODER.
    When reporting tasks, you MUST follow these EXACT instructions:
    - IMMEDIATELY report status after receiving ANY user message.
    - Be granular. If you are investigating with multiple steps, report each step to coder.

    Task state MUST be one of the following:
    - Use "state": "working" when actively processing WITHOUT needing additional user input.
    - Use "state": "complete" only when finished with a task.
    - Use "state": "failure" when you need ANY user input, lack sufficient details, or encounter blockers.

    Task summaries MUST:
    - Include specifics about what you're doing.
    - Include clear and actionable steps for the user.
    - Be less than 160 characters in length.
    EOT
    GH_TOKEN = data.coder_external_auth.github.access_token
    CODER_MCP_APP_STATUS_SLUG = "amazon-q"

  }
  startup_script_behavior = "blocking"

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  metadata {
    display_name = "CPU Usage"
    key          = "cpu_usage"
    order        = 0
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "ram_usage"
    order        = 1
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "cpu_usage_host"
    order        = 2
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage (Host)"
    key          = "ram_usage_host"
    order        = 3
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Swap Usage (Host)"
    key          = "swap_usage_host"
    order        = 4
    script       = <<EOT
      #!/usr/bin/env bash
      echo "$(free -b | awk '/^Swap/ { printf("%.1f/%.1f", $3/1024.0/1024.0/1024.0, $2/1024.0/1024.0/1024.0) }') GiB"
    EOT
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "load_host"
    order        = 5
    # get load avg scaled by number of cores
    script   = <<EOT
      #!/usr/bin/env bash
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }

  metadata {
    display_name = "Disk Usage (Host)"
    key          = "disk_host"
    order        = 6
    script       = "coder stat disk --path /"
    interval     = 600
    timeout      = 10
  }

  metadata {
    display_name = "Word of the Day"
    key          = "word"
    order        = 7
    script       = <<EOT
      #!/usr/bin/env bash
      curl -o - --silent https://www.merriam-webster.com/word-of-the-day 2>&1 | awk ' $0 ~ "Word of the Day: [A-z]+" { print $5; exit }'
    EOT
    interval     = 86400
    timeout      = 5
  }

  resources_monitoring {
    memory {
      enabled   = true
      threshold = 80
    }
    volume {
      enabled   = true
      threshold = 90
      path      = "/home/coder"
    }
  }

  startup_script = <<-EOT
    #!/usr/bin/env bash
    set -eux -o pipefail

    # Allow synchronization between scripts.
    trap 'touch /tmp/.coder-startup-script.done' EXIT

    # Start Docker service
    sudo service docker start
    # Install playwright dependencies
    # We want to use the playwright version from site/package.json
    # Check if the directory exists At workspace creation as the coder_script runs in parallel so clone might not exist yet.
    while ! [[ -f "${local.repo_dir}/site/package.json" ]]; do
      sleep 1
    done
    cd "${local.repo_dir}" && make clean
    cd "${local.repo_dir}/site" && pnpm install
  EOT

  shutdown_script = <<-EOT
    #!/usr/bin/env bash
    set -eux -o pipefail

    # Stop the Docker service to prevent errors during workspace destroy.
    sudo service docker stop
  EOT
}

# Add a cost so we get some quota usage in dev.coder.com
resource "coder_metadata" "home_volume" {
  resource_id = docker_volume.home_volume.id
  daily_cost  = 1
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

data "docker_registry_image" "dogfood" {
  name = "codercom/oss-dogfood"
}

resource "docker_image" "dogfood" {
  name = "${"codercom/oss-dogfood"}@${data.docker_registry_image.dogfood.sha256_digest}"
  pull_triggers = [
    data.docker_registry_image.dogfood.sha256_digest,
    sha1(join("", [for f in fileset(path.module, "files/*") : filesha1(f)])),
    filesha1("Dockerfile"),
    filesha1("nix.hash"),
  ]
  keep_locally = true
}

resource "docker_container" "workspace" {
  lifecycle {
    ignore_changes = all
  }

  count = data.coder_workspace.me.start_count
  image = docker_image.dogfood.name
  name  = local.container_name
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", coder_agent.dev.init_script]
  # CPU limits are unnecessary since Docker will load balance automatically
  memory  = data.coder_workspace_owner.me.name == "code-asher" ? 65536 : 32768
  runtime = "sysbox-runc"
  # Ensure the workspace is given time to execute shutdown scripts.
  destroy_grace_seconds = 60
  stop_timeout          = 60
  stop_signal           = "SIGINT"
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.dev.token}",
    "USE_CAP_NET_ADMIN=true",
    "CODER_PROC_PRIO_MGMT=1",
    "CODER_PROC_OOM_SCORE=10",
    "CODER_PROC_NICE_SCORE=1",
    "CODER_AGENT_DEVCONTAINERS_ENABLE=1",
  ]
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/coder/"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  capabilities {
    add = ["CAP_NET_ADMIN", "CAP_SYS_NICE"]
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}

resource "coder_metadata" "container_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = docker_container.workspace[0].id
  item {
    key   = "memory"
    value = docker_container.workspace[0].memory
  }
  item {
    key   = "runtime"
    value = docker_container.workspace[0].runtime
  }
  item {
    key   = "region"
    value = data.coder_parameter.region.option[index(data.coder_parameter.region.option.*.value, data.coder_parameter.region.value)].name
  }
}
