# Managed in https://github.com/coder/templates
terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

data "coder_workspace" "me" {}

data "coder_workspace_owner" "me" {}

# Minimum vCPUs needed 
data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "CPU cores for your individual workspace"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min = 2
    max = 8
  }
  form_type = "input"
  mutable   = true
  default   = 4
  order     = 1
}

# Minimum GB memory needed 
data "coder_parameter" "memory" {
  name        = "Memory (__ GB)"
  type        = "number"
  description = "Memory (__ GB) for your individual workspace"
  icon        = "https://www.vhv.rs/dpng/d/33-338595_random-access-memory-logo-hd-png-download.png"
  validation {
    min = 4
    max = 16
  }
  form_type = "input"
  mutable   = true
  default   = 8
  order     = 2
}

data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage for '${local.home_dir}'! This will persist after the workspace's K8s Pod is shutdown or deleted."
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 10
    max       = 50
    monotonic = "increasing"
  }
  form_type = "slider"
  mutable   = true
  default   = 10
  order     = 3
}

data "coder_parameter" "image" {
  name        = "Container Image"
  type        = "string"
  description = "What container image and language do you want?"
  mutable     = true
  default     = "codercom/enterprise-base:ubuntu"
  icon        = "https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png"
  form_type   = "dropdown"
  option {
    name  = "Node React"
    value = "codercom/enterprise-node:latest"
    icon  = "https://cdn.freebiesupply.com/logos/large/2x/nodejs-icon-logo-png-transparent.png"
  }
  option {
    name  = "Golang"
    value = "codercom/enterprise-golang:latest"
    icon  = "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Go_Logo_Blue.svg/1200px-Go_Logo_Blue.svg.png"
  }
  option {
    name  = "Java"
    value = "codercom/enterprise-java:latest"
    icon  = "https://assets.stickpng.com/images/58480979cef1014c0b5e4901.png"
  }
  option {
    name  = "Base including Python"
    value = "codercom/enterprise-base:ubuntu"
    icon  = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Python-logo-notext.svg/1869px-Python-logo-notext.svg.png"
  }
  order = 4
}

#data "coder_external_auth" "github" {
#  id       = "primary-github"
#  optional = true
#}

data "coder_parameter" "repo" {
  name        = "Source Code Repository"
  type        = "string"
  description = "What source code repository do you want to clone?"
  mutable     = true
  form_type   = "dropdown"
  default     = "https://github.com/coder-contrib/coder"
  icon        = "https://avatars.githubusercontent.com/u/95932066?s=200&v=4"

  option {
    name  = "PAC-MAN"
    value = "https://github.com/coder-contrib/pacman-nodejs"
    icon  = "https://assets.stickpng.com/images/5a18871c8d421802430d2d05.png"
  }
  option {
    name  = "Coder v2 OSS project"
    value = "https://github.com/coder-contrib/coder"
    icon  = "/icon/coder.svg"
  }
  option {
    name  = "Coder code-server project"
    value = "https://github.com/coder/code-server"
    icon  = "/icon/code.svg"
  }
  order = 5
}

data "coder_parameter" "startup-script" {
  name        = "startup_script"
  type        = "string"
  description = "Script to run on startup!"
  mutable     = contains(data.coder_workspace_owner.me.groups, "admins")
  default     = ""
  icon        = "/icon/terminal.svg"
  form_type   = "textarea"
  order       = 6
}

locals {
  home_dir        = "/home/coder"
  folder_name     = try(element(split("/", data.coder_parameter.repo.value), length(split("/", data.coder_parameter.repo.value)) - 1), "")
  repo_owner_name = try(element(split("/", data.coder_parameter.repo.value), length(split("/", data.coder_parameter.repo.value)) - 2), "")
  regions = {
    "us-east-2" = {
      name = "Ohio"
      icon = "/emojis/1f1fa-1f1f8.png" # 🇺🇸
    }
    "us-west-2" = {
      name = "Oregon"
      icon = "/emojis/1f1fa-1f1f8.png" # 🇺🇸
    }
    "eu-west-2" = {
      name = "London"
      icon = "/emojis/1f1ec-1f1e7.png" # 🇬🇧
    }
  }
  default_namespace = "coder"
  namespaces = {
    "coder" = {
      name = "coder"
      icon = "/emojis/1f947.png"
    }
  }
}

data "coder_parameter" "namespace" {
  count        = contains(["phorcys420", "ju-pe"], data.coder_workspace_owner.me.name) ? 1 : 0
  name         = "namespace"
  display_name = "K8s Namespace"
  description  = "Choose the namespace to deploy to (NOTE: Only admins can see this)."
  mutable      = true
  default      = local.default_namespace
  form_type    = "dropdown"
  dynamic "option" {
    for_each = local.namespaces
    content {
      value = option.key
      name  = option.value.name
      icon  = option.value.icon
    }
  }
  order = 7
}

data "coder_parameter" "location" {
  name         = "location"
  display_name = "Location"
  description  = "Choose the location that's closest to you for the best connection!"
  mutable      = true
  default      = "us-east-2"
  form_type    = "dropdown"
  dynamic "option" {
    for_each = local.regions
    content {
      value = option.key
      name  = option.value.name
      icon  = option.value.icon
    }
  }
  order = 8
}

resource "coder_agent" "pod-agent" {
  os             = "linux"
  arch           = "amd64"
  startup_script = data.coder_parameter.startup-script.value
  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    # get load avg scaled by number of cores
    script   = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }

  display_apps {
    vscode                 = false
    vscode_insiders        = false
    ssh_helper             = true
    port_forwarding_helper = true
    web_terminal           = true
  }

  dir                     = local.home_dir
  startup_script_behavior = "blocking"
}

resource "coder_app" "preview-pac-man" {
  count = data.coder_parameter.repo.value == "https://github.com/coder-contrib/pacman-nodejs" ? 1 : 0

  agent_id     = coder_agent.pod-agent.id
  slug         = "pacman"
  display_name = "Play PAC-MAN"
  icon         = "https://assets.stickpng.com/images/5a18871c8d421802430d2d05.png"
  url          = "http://localhost:8080"
  tooltip      = "Click to open and play PAC-MAN!"
  share        = "owner"
  subdomain    = true
  open_in      = "slim-window"
  order        = 998
  healthcheck {
    url       = "http://localhost:8080"
    interval  = 20
    threshold = 6
  }
}

locals {
  # This is the init script for the main workspace container that runs before the
  # agent starts to configure workspace process logging.
  exectrace_init_script = <<EOF
    set -eu
    pidns_inum=$(readlink /proc/self/ns/pid | sed 's/[^0-9]//g')
    if [ -z "$pidns_inum" ]; then
      echo "Could not determine process ID namespace inum"
      exit 1
    fi

    # Before we start the script, does curl exist?
    if ! command -v curl >/dev/null 2>&1; then
      echo "curl is required to download the Coder binary"
      echo "Please install curl to your image and try again"
      # 127 is command not found.
      exit 127
    fi

    echo "Sending process ID namespace inum to exectrace sidecar"
    rc=0
    max_retry=5
    counter=0
    until [ $counter -ge $max_retry ]; do
      set +e
      curl \
        --fail \
        --silent \
        --connect-timeout 5 \
        -X POST \
        -H "Content-Type: text/plain" \
        --data "$pidns_inum" \
        http://127.0.0.1:56123
      rc=$?
      set -e
      if [ $rc -eq 0 ]; then
        break
      fi

      counter=$((counter+1))
      echo "Curl failed with exit code $${rc}, attempt $${counter}/$${max_retry}; Retrying in 3 seconds..."
      sleep 3
    done
    if [ $rc -ne 0 ]; then
      echo "Failed to send process ID namespace inum to exectrace sidecar"
      exit $rc
    fi

  EOF
}

locals {
  deployment_name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
  deployment_labels = {
    "app.kubernetes.io/name"     = "coder-workspace"
    "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
    "app.kubernetes.io/part-of"  = "coder"
    "com.coder.resource"         = "true"
    "com.coder.workspace.id"     = data.coder_workspace.me.id
    "com.coder.workspace.name"   = data.coder_workspace.me.name
    "com.coder.user.id"          = data.coder_workspace_owner.me.id
    "com.coder.user.username"    = data.coder_workspace_owner.me.name
  }
  deployment_annotations = {
    "com.coder.user.email" = data.coder_workspace_owner.me.email
  }
}

resource "kubernetes_deployment" "main" {
  wait_for_rollout = false
  metadata {
    name        = local.deployment_name
    namespace   = try(data.coder_parameter.namespace[0].value, local.default_namespace)
    labels      = local.deployment_labels
    annotations = local.deployment_annotations
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.deployment_labels
    }
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = local.deployment_labels
      }
      spec {
        security_context {
          run_as_user = 1000
          fs_group    = 1000
        }

        container {
          name              = "coder-workspace"
          image             = data.coder_parameter.image.value
          image_pull_policy = "IfNotPresent"
          command = [
            "sh",
            "-c",
            join("\n\n", [
              # local.exectrace_init_script,
              coder_agent.pod-agent.init_script
            ])
          ]
          security_context {
            run_as_user = "1000"
          }
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.pod-agent.token
          }

#          env {
#            name = "GH_TOKEN"
#            value = data.coder_external_auth.github.access_token
#          }

          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "512Mi"
            }
            limits = {
              "cpu"    = "${data.coder_parameter.cpu.value}"
              "memory" = "${data.coder_parameter.memory.value}Gi"
            }
          }
          volume_mount {
            mount_path = local.home_dir
            name       = "home-directory"
            read_only  = false
          }
        }

        # Sidecar process logging container
        # container {
        #   name              = "exectrace"
        #   image             = "ghcr.io/coder/exectrace:latest"
        #   image_pull_policy = "Always"
        #   command = [
        #     "/opt/exectrace",
        #     "--init-address", "127.0.0.1:56123",
        #     "--label", "workspace_id=${data.coder_workspace.me.id}",
        #     "--label", "workspace_name=${data.coder_workspace.me.name}",
        #     "--label", "user_id=${data.coder_workspace_owner.me.id}",
        #     "--label", "username=${data.coder_workspace_owner.me.name}",
        #     "--label", "user_email=${data.coder_workspace_owner.me.email}",
        #   ]
        #   security_context {
        #     run_as_user  = "0"
        #     run_as_group = "0"
        #     privileged   = true
        #   }
        #   #Process logging env variables
        #   env {
        #     name  = "CODER_AGENT_SUBSYSTEM"
        #     value = "exectrace"
        #   }
        # }

        volume {
          name = "home-directory"
          empty_dir {}
        }

        affinity {
          // This affinity attempts to spread out all workspace pods evenly across
          // nodes.
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1
              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["coder-workspace"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_deployment.main.id
  item {
    key   = "Docker Image"
    value = data.coder_parameter.image.value
  }
  item {
    key   = "Repository Cloned"
    value = "${local.repo_owner_name}/${local.folder_name}"
  }
  item {
    key   = "Region"
    value = local.regions[data.coder_parameter.location.value].name
  }
  item {
    key   = "OS"
    value = coder_agent.pod-agent.os
  }
  item {
    key   = "Architecture"
    value = coder_agent.pod-agent.arch
  }
  item {
    key   = "K8s Deployment Name"
    value = local.deployment_name
  }
}