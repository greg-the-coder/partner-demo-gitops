terraform {
    required_providers {
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = "2.37.1"
        }
        coder = {
            source = "coder/coder"
            version = "2.5.3"

        }
        random = {
            source = "hashicorp/random"
            version = "3.7.2"
        }
    }
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to create workspaces in (must exist prior to creating workspaces). If the Coder host is itself running as a Pod on the same Kubernetes cluster as you are deploying workspaces to, set this to the same namespace."
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 Cores"
    value = "2"
  }
  option {
    name  = "4 Cores"
    value = "4"
  }
  option {
    name  = "6 Cores"
    value = "6"
  }
  option {
    name  = "8 Cores"
    value = "8"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory in GB"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 GB"
    value = "2"
  }
  option {
    name  = "4 GB"
    value = "4"
  }
  option {
    name  = "6 GB"
    value = "6"
  }
  option {
    name  = "8 GB"
    value = "8"
  }
}

data "coder_parameter" "home_disk_size" {
  name         = "home_disk_size"
  display_name = "Home disk size"
  description  = "The size of the home disk in GB"
  default      = "10"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  validation {
    min = 1
    max = 99999
  }
}

data "coder_parameter" "git-repo" {
    name         = "git-repo"
    display_name = "Git Repository"
    description  = "Clone a Git repo over HTTPS (if public) or SSH (if private)."
    mutable      = false
    default      = ""
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
    cost = 1
    region = "us-east-2"
    home_folder = data.coder_parameter.git-repo.value == "" ? "/home/coder" : join("/", [
        "/home/coder", element(split(".", element(split("/", data.coder_parameter.git-repo.value), -1)), 0)
    ])
    task_prompt = join(" ", [
        "1. Post a 'task started' update to Coder.",
        "2. A Next.js app is already in the repo, with a tmux session named dev-server running npm run dev. Do not try to run another dev server unless you need to.",
        "3. If the user asks for a brand-new site in step 6 (instead of editing the current contract site), kill dev-server and build a static site for speed.",
        "4. Else leave dev-server running—do not re-run npm run dev.",
        "5. Finally, review all of your memory."
    ])
    system_prompt = <<-EOT
        You have a Next.js application in your directory and there is a tmux session called `dev-server` that is running the application already.
        
        - Always use port 3000 so the user has a consistent preview to see their work. Users cannot preview other ports
        - If the dev server is already running but broken, kill the dev server to run on port 3000.
        - Avoid building the project for production. Just use dev servers (and ALWAYS VIA desktop-commander as mentioned below)
        - When you think you have finished, you should use Playwright to review the HTML to ensure it is working as expected.
        - Feel free to fix anything bad you see.

        Always run long-running commands (e.g. `pnpm dev` or `npm run dev`) using desktop-commander so it runs it in the background and users can prompt you. Other short-lived commands (build, test, cd, write, read, view, etc) can run normally. 
        Never run the dev server without desktop-commander. This will cause you to stall and get stuck.
        For previewing, always use the dev server for fast feedback loops (never do a full Next.js build, for exmaple). Next.js or simple HTML/static is preferred for web applications, but pick the best framework for the job.
        
        The dev server will be on localhost:3000 and NEVER start on another port. The user depends on localhost:3000. If the dev server crashes for some reason, kill port 3000 (or the desktop-commander session) and restart it.
        
        After large changes, use Playwright to ensure your changes work (preview localhost:3000). Take a screenshot, look at the screenshot. Also look at the HTML output from Playwright. If there are errors or something looks "off," fix it.
        Whenever waiting for a PR review, keep on retrying indefinitely until you get a review. Even if requests are timing out.
        Aim to autonomously investigate and solve issues the user gives you and test your work, whenever possible.
        Avoid shortcuts like mocking tests. When you get stuck, you can ask the user but opt for autonomy.
        
        In your task reports to Coder:
        - Be specific about what you're doing
        - Clearly indicate what information you need from the user when in "failure" state
        - Keep it under 160 characters
        - Make it actionable

        If you're being tasked to create a Coder template, then you must ALWAYS ask the user for permission to push it. You are NOT allowed to push templates or create workspaces from them without the users explicit approval.

        When reporting URLs to Coder, do not use localhost. Instead, run `env | grep CODER`, and use a URL like https://preview--dev--CODER_WORKSPACE_NAME--CODER_WORKSPACE_OWNER.demo.coder.com/ but replace it with the proper env vars. That proxies port 3000.
    EOT
    pre_install_script = <<-EOT
        git clone https://github.com/bcdr-demos/contract-tracker-demo project
        tmux new-session -d -s dev-server -c $HOME/project "npm install && npm run dev"
        npm config set prefix=~
    EOT
}

resource "coder_agent" "dev" {
    arch = "amd64"
    os = "linux"
    dir = local.home_folder
    env = {
        CODER_MCP_CLAUDE_TASK_PROMPT        = local.task_prompt
        CODER_MCP_CLAUDE_SYSTEM_PROMPT      = local.system_prompt
        CLAUDE_CODE_USE_BEDROCK = "1",
        ANTHROPIC_MODEL = "us.anthropic.claude-3-7-sonnet-20250219-v1:0",
        ANTHROPIC_SMALL_FAST_MODEL = "us.anthropic.claude-3-5-haiku-20241022-v1:0",
        CODER_MCP_APP_STATUS_SLUG = "claude-code"
    }
    display_apps {
        vscode          = false
        vscode_insiders = false
        web_terminal    = true
        ssh_helper      = false
    }
}

module "coder-login" {
    source   = "registry.coder.com/coder/coder-login/coder"
    version  = "1.0.15"
    agent_id = coder_agent.dev.id
}

module "git-clone" {
    count = data.coder_parameter.git-repo.value == "" ? 0 : 1
    source   = "registry.coder.com/coder/git-clone/coder"
    version  = "1.0.18"
    agent_id = coder_agent.dev.id
    url      = data.coder_parameter.git-repo.value
    base_dir = local.home_folder
}

module "vscode-web" {
    source         = "registry.coder.com/coder/vscode-web/coder"
    version        = "1.2.0"
    agent_id       = coder_agent.dev.id
    folder         = local.home_folder
    accept_license = true
    subdomain = true
    order = 0
}

module "cursor" {
    source   = "registry.coder.com/coder/cursor/coder"
    version  = "1.1.0"
    agent_id = coder_agent.dev.id
    order = 1
}

module "claude-code" {
    source = "git::https://github.com/coder/registry.git//registry/coder/modules/claude-code?ref=claude-code-web"

    agent_id            = coder_agent.dev.id
    folder              = local.home_folder
    install_claude_code = true

    experiment_pre_install_script = local.pre_install_script
    experiment_use_screen = false
    experiment_use_tmux = true
    experiment_report_tasks = true
    order = 2
}

resource "coder_app" "preview" {
    agent_id     = coder_agent.dev.id
    slug         = "preview"
    display_name = "Preview your app"
    icon         = "${data.coder_workspace.me.access_url}/emojis/1f50e.png"
    url          = "http://localhost:3000"
    share        = "authenticated"
    subdomain    = true
    open_in      = "tab"
    order = 3
    healthcheck {
        url       = "http://localhost:3000/"
        interval  = 5
        threshold = 15
    }
}

resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.id}-home"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${data.coder_workspace.me.id}"
      "app.kubernetes.io/part-of"  = "coder"
      //Coder-specific labels.
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.me.id
      "com.coder.workspace.name" = data.coder_workspace.me.name
      "com.coder.user.id"        = data.coder_workspace_owner.me.id
      "com.coder.user.username"  = data.coder_workspace_owner.me.name
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.coder_parameter.home_disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "dev" {
  count = data.coder_workspace.me.start_count
  depends_on = [
    kubernetes_persistent_volume_claim.home
  ]
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
    annotations = {
      "com.coder.user.email" = data.coder_workspace_owner.me.email
    }
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
    strategy {
      type = "Recreate"
    }

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
          security_context {
            run_as_user = "1000"
          }
          env {
            name  = "CODER_AGENT_TOKEN"
            value = coder_agent.dev.token
          }
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
            mount_path = "/home/coder"
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

resource "coder_metadata" "pod_info" {
    count = data.coder_workspace.me.start_count
    resource_id = kubernetes_deployment.dev[0].id
    daily_cost = local.cost
}
