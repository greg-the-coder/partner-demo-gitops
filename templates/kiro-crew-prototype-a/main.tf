terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.37.1"
    }
    coder = {
      source  = "coder/coder"
      version = ">= 2.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace to create workspaces in."
  default     = "coder"
}

locals {
  home_dir = "/home/coder"
  bin_path = "/home/coder/.local/bin:/home/coder/bin:/home/coder/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  cost     = 2
}

# ── Parameters ────────────────────────────────────────────────────────────────

data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "CPU cores for your individual workspace"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min = 2
    max = 8
  }
  form_type   = "input"
  mutable     = true
  default     = 2
  order       = 1
}

data "coder_parameter" "memory" {
  name        = "Memory (__ GB)"
  type        = "number"
  description = "Memory (GB) for your individual workspace"
  icon        = "https://www.vhv.rs/dpng/d/33-338595_random-access-memory-logo-hd-png-download.png"
  validation {
    min = 4
    max = 16
  }
  form_type   = "input"
  mutable     = true
  default     = 4
  order       = 2
}

data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage for '${local.home_dir}'. Persists across restarts."
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min      = 10
    max      = 50
    monotonic = "increasing"
  }
  form_type   = "slider"
  mutable     = true
  default     = 30
  order       = 3
}

data "coder_parameter" "git_repo" {
  name         = "git_repo"
  display_name = "Git repository"
  description  = "Repository to clone into the workspace on first start."
  default      = "https://github.com/greg-the-coder/aws-rag-prototyping.git"
  order        = 4
}

# ── Coder workspace/owner metadata ────────────────────────────────────────────

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# ── Coder Agent ───────────────────────────────────────────────────────────────

resource "coder_agent" "dev" {
  arch = "amd64"
  os   = "linux"
  dir  = local.home_dir
  env  = { PATH = local.bin_path }

  display_apps {
    vscode          = false
    vscode_insiders = false
    web_terminal    = true
    ssh_helper      = false
  }

  startup_script_behavior = "blocking"
  startup_script          = file("${path.module}/startup.sh")
}

# ── Coder registry modules ────────────────────────────────────────────────────

module "coder-login" {
  source   = "registry.coder.com/coder/coder-login/coder"
  version  = "1.1.0"
  agent_id = coder_agent.dev.id
}

module "code-server" {
  source    = "registry.coder.com/coder/code-server/coder"
  version   = "1.3.1"
  agent_id  = coder_agent.dev.id
  folder    = local.home_dir
  subdomain = false
  order     = 0
}

module "kiro" {
  source   = "registry.coder.com/coder/kiro/coder"
  version  = "1.1.0"
  agent_id = coder_agent.dev.id
  order    = 1
}

# ── KiroCrew module (Prototype A — no external auth) ─────────────────────────
# Installs the KiroCrew gateway as a coder_script, surfaces the KiroCrew
# dashboard as a coder_app with healthcheck. AWS credentials come from the
# pod's IAM role (IRSA) or manual `aws configure`.

module "kirocrew" {
  source     = "./modules/kirocrew"
  agent_id   = coder_agent.dev.id
  port       = 8899
  use_cached = true
  order      = 3

  # The module encapsulates everything else: it derives the dashboard app's
  # subdomain origin, trusts it in the gateway's Host/Origin allowlist, sets
  # dashboard.url, and runs a token-minting redirector so the "kirocrew" app
  # tile self-authenticates.
}

# ── Manual Kiro CLI auth app ──────────────────────────────────────────────────

resource "coder_app" "kiro_cli" {
  agent_id     = coder_agent.dev.id
  slug         = "kiro-auth"
  display_name = "Kiro CLI"
  icon         = "${data.coder_workspace.me.access_url}/icon/kiro.svg"
  command      = "kiro-cli"
  share        = "owner"
  order        = 2
}

# ── Git helpers ───────────────────────────────────────────────────────────────

module "git-config" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/git-config/coder"
  version  = "1.0.33"
  agent_id = coder_agent.dev.id
}

module "git-clone" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/git-clone/coder"
  version  = "1.2.3"
  agent_id = coder_agent.dev.id
  url      = data.coder_parameter.git_repo.value
}

# ── Kubernetes PVC ────────────────────────────────────────────────────────────

resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-home"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace_owner.me.id
      "com.coder.user.username"    = data.coder_workspace_owner.me.name
    }
    annotations = { "com.coder.user.email" = data.coder_workspace_owner.me.email }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources { requests = { storage = "${data.coder_parameter.disk_size.value}Gi" } }
  }
}

# ── Kubernetes Deployment ──────────────────────────────────────────────────────

resource "kubernetes_deployment" "dev" {
  count            = data.coder_workspace.me.start_count
  depends_on       = [kubernetes_persistent_volume_claim.home]
  wait_for_rollout = false

  metadata {
    name      = "coder-${data.coder_workspace.me.id}"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      "com.coder.resource"         = "true"
      "com.coder.workspace.id"     = data.coder_workspace.me.id
      "com.coder.workspace.name"   = data.coder_workspace.me.name
      "com.coder.user.id"          = data.coder_workspace_owner.me.id
      "com.coder.user.username"    = data.coder_workspace_owner.me.name
    }
    annotations = { "com.coder.user.email" = data.coder_workspace_owner.me.email }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "coder-workspace"
        "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
        "app.kubernetes.io/part-of"  = "coder"
        "com.coder.resource"         = "true"
        "com.coder.workspace.id"     = data.coder_workspace.me.id
        "com.coder.workspace.name"   = data.coder_workspace.me.name
        "com.coder.user.id"          = data.coder_workspace_owner.me.id
        "com.coder.user.username"    = data.coder_workspace_owner.me.name
      }
    }
    strategy { type = "Recreate" }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "coder-workspace"
          "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
          "app.kubernetes.io/part-of"  = "coder"
          "com.coder.resource"         = "true"
          "com.coder.workspace.id"     = data.coder_workspace.me.id
          "com.coder.workspace.name"   = data.coder_workspace.me.name
          "com.coder.user.id"          = data.coder_workspace_owner.me.id
          "com.coder.user.username"    = data.coder_workspace_owner.me.name
        }
      }
      spec {
        security_context {
          run_as_user = 1000
          fs_group    = 1000
        }
        service_account_name = "coder"

        container {
          name              = "dev"
          image             = "codercom/enterprise-base:ubuntu"
          image_pull_policy = "Always"
          command           = ["sh", "-c", coder_agent.dev.init_script]
          security_context  { run_as_user = "1000" }

          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.dev.token
          }

          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "512Mi"
            }
            limits   = {
              "cpu"    = "${data.coder_parameter.cpu.value}"
              "memory" = "${data.coder_parameter.memory.value}Gi"
            }
          }

          volume_mount {
            mount_path = local.home_dir
            name       = "home"
            read_only  = false
          }
        }

        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.home.metadata.0.name
            read_only  = false
          }
        }

        affinity {
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

resource "coder_metadata" "pod_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_deployment.dev[0].id
  daily_cost  = local.cost
}
