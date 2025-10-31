terraform {
    required_providers {
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = "2.37.1"
        }
        coder = {
            source = "coder/coder"
            version = "2.8.0"
        }
        random = {
            source = "hashicorp/random"
            version = "3.7.2"
        }
    }
}

variable "eks_cluster_name" {
  type        = string
  description = "The AWS EKS Kubernetes cluster name that Coder is deployed within."
  default     = "coder-eks-cluster"
}

variable "namespace" {
  type        = string
  description = "The Kubernetes namespace to create workspaces in (must exist prior to creating workspaces). If the Coder host is itself running as a Pod on the same Kubernetes cluster as you are deploying workspaces to, set this to the same namespace."
  default     = "coder"
}

variable "anthropic_model" {
  type        = string
  description = "The AWS Inference profile ID of the base Anthropic model to use with Claude Code"
  default     = "global.anthropic.claude-sonnet-4-5-20250929-v1:0"
}

variable "anthropic_small_fast_model" {
  type        = string
  description = "The AWS Inference profile ID of the small fast Anthropic model to use with Claude Code"
  default     = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
}

variable "postgresql_version" {
  type        = string
  description = "The AWS Aurora PostgreSQL Database Engine Version to deploy"
  default     = "16.8"
}

locals {
  home_dir        = "/home/coder"
}

# Minimum vCPUs needed 
data "coder_parameter" "cpu" {
  name        = "CPU cores"
  type        = "number"
  description = "CPU cores for your individual workspace"
  icon        = "https://png.pngtree.com/png-clipart/20191122/original/pngtree-processor-icon-png-image_5165793.jpg"
  validation {
    min = 4
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
  default   = 4
  order     = 2
}

data "coder_parameter" "home_disk_size" {
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

data "coder_parameter" "ai_prompt" {
    type        = "string"
    name        = "AI Prompt"
    icon        = "/emojis/1f4ac.png"
    description = "Create a task prompt for Claude Code"
    default = "Look for an AWS RAG Prototyping repo in the Coder Workspace.  If found, create a new Python3 virtual environment, pip install the requirements.txt and then start the app via streamlit."
    mutable     = false
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "dev" {
    arch = "amd64"
    os = "linux"
    dir = local.home_dir
  startup_script = <<-EOT
    set -e
    sudo apt update
    sudo apt install -y curl unzip postgresql-client telnet

    # install AWS CLI
    if [ ! -d "aws" ]; then
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      aws --version
      rm awscliv2.zip
    fi

    # install AWS CDK
    if ! command -v cdk &> /dev/null; then
      echo "Installing AWS CDK..."
      # Install Node.js and npm (required for CDK)
      # Add NodeSource repository for the latest LTS version
      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
      sudo apt-get install nodejs -y
      sudo npm install -g npm@11.3.0

      # Verify installation
      node -v
      npm -v

      # Install AWS CDK globally
      sudo npm install -g aws-cdk
      
      # Verify CDK installation
      cdk --version
      
      echo "AWS CDK installation completed"
    else
      echo "AWS CDK is already installed"
      cdk --version
    fi
   
    # Enable Vector extension on Aurora PostgreSQL instance
    PGPASSWORD="YourStrongPasswordHere1" psql -h ${module.aurora-pgvector.aurora_postgres_1_endpoint} -U dbadmin -d mydb1 -c "CREATE EXTENSION IF NOT EXISTS vector;"

  EOT

    env = {
        CODER_MCP_CLAUDE_TASK_PROMPT        = local.task_prompt
        CODER_MCP_CLAUDE_SYSTEM_PROMPT      = local.system_prompt
        CLAUDE_CODE_USE_BEDROCK = "1"
        ANTHROPIC_MODEL = var.anthropic_model
        ANTHROPIC_SMALL_FAST_MODEL = var.anthropic_small_fast_model
        CODER_MCP_APP_STATUS_SLUG = "claude-code"
        PGVECTOR_USER = "dbadmin"
        PGVECTOR_PASSWORD = "YourStrongPasswordHere1"
        PGVECTOR_HOST = module.aurora-pgvector.aurora_postgres_1_endpoint
        PGVECTOR_PORT = "5432"
        PGVECTOR_DATABASE = "mydb1"
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
    version  = "1.1.0"
    agent_id = coder_agent.dev.id
}

# Prompt the user for the git repo URL
data "coder_parameter" "git_repo" {
  name         = "git_repo"
  display_name = "Git repository"
  default      = "https://github.com/greg-the-coder/aws-rag-prototyping.git"
}

# Clone the repository 
module "git_clone" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/git-clone/coder"
  version  = "1.2.0"
  agent_id = coder_agent.dev.id
  url      = data.coder_parameter.git_repo.value
}

# Create a code-server instance for the cloned repository
module "code-server" {
  count      = data.coder_workspace.me.start_count
  source     = "registry.coder.com/coder/code-server/coder"
  version    = "1.3.1"
  agent_id   = coder_agent.dev.id
  order      = 1
  folder     = local.home_dir
  subdomain  = false
}

module "claude-code" {
    count               = data.coder_workspace.me.start_count
    source              = "registry.coder.com/coder/claude-code/coder"
    version             = "2.2.0"
    agent_id            = coder_agent.dev.id
    folder              = local.home_dir
    subdomain           = false

    install_claude_code = true
    order               = 999

    experiment_report_tasks = true
    experiment_pre_install_script = <<-EOF
        # If user doesn't have a Github account or aren't 
        # part of the coder-contrib organization, then they can use the `coder-contrib-bot` account.
        if [ ! -z "$GH_USERNAME" ]; then
            unset -v GIT_ASKPASS
            unset -v GIT_SSH_COMMAND
        fi
    EOF
}

module "kiro" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/kiro/coder"
  version  = "1.1.0"
  agent_id = coder_agent.dev.id
  folder   = local.home_dir
}

resource "coder_app" "preview" {
    agent_id     = coder_agent.dev.id
    slug         = "preview"
    display_name = "Preview your app"
    icon         = "${data.coder_workspace.me.access_url}/emojis/1f50e.png"
    url          = "http://localhost:8501"
    share        = "authenticated"
    subdomain    = false
    open_in      = "tab"
    order = 3
    healthcheck {
        url       = "http://localhost:8501/"
        interval  = 5
        threshold = 15
    }
}

locals {
    cost = 2
    region = "us-west-2"
}

locals {
    port = 8501
    domain = element(split("/", data.coder_workspace.me.access_url), -1)
}

locals {
    task_prompt = join(" ", [
        "First, post a 'task started' update to Coder.",
        "Then, review all of your memory.",
        "Finally, ${data.coder_parameter.ai_prompt.value}.",
    ])
    system_prompt = <<-EOT
        Hey! First, report an initial task to Coder to show you have started! The user has provided you with a prompt of something to create. Create it the best you can, and keep it as succinct as possible.
        
        If you're being tasked to create a web application, then:
        - ALWAYS start the server using `python3` or `node` on localhost:${local.port}.
        - BEFORE starting the server, ALWAYS attempt to kill ANY process using port ${local.port}, and then run the dev server on port ${local.port}.
        - ALWAYS build the project using dev servers (and ALWAYS VIA desktop-commander)
        - When finished, you should use Playwright to review the HTML to ensure it is working as expected.

        ALWAYS run long-running commands (e.g. `pnpm dev` or `npm run dev`) using desktop-commander so it runs it in the background and users can prompt you.  Other short-lived commands (build, test, cd, write, read, view, etc) can run normally.

        NEVER run the dev server without desktop-commander.

        For previewing, always use the dev server for fast feedback loops (never do a full Next.js build, for exmaple). A simple HTML/static is preferred for web applications, but pick the best AND lightest framework for the job.
        
        The dev server will ALWAYS be on localhost:${local.port} and NEVER start on another port. If the dev server crashes for some reason, kill port ${local.port} (or the desktop-commander session) and restart the dev server.

        After large changes, use Playwright to ensure your changes work (preview localhost:${local.port}). Take a screenshot, look at the screenshot. Also look at the HTML output from Playwright. If there are errors or something looks "off," fix it.
        
        Aim to autonomously investigate and solve issues the user gives you and test your work, whenever possible.
        
        Avoid shortcuts like mocking tests. When you get stuck, you can ask the user but opt for autonomy.
        
        In your task reports to Coder:
        - Be specific about what you're doing
        - Clearly indicate what information you need from the user when in "failure" state
        - Keep it under 160 characters
        - Make it actionable

        If you're being tasked to create a Coder template, then,
        - You must ALWAYS ask the user for permission to push it. 
        - You are NOT allowed to push templates OR create workspaces from them without the users explicit approval.

        When reporting URLs to Coder, report to "https://preview--dev--${data.coder_workspace.me.name}--${data.coder_workspace_owner.me.name}.${local.domain}/" that proxies port ${local.port}
    EOT
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

module "aurora-pgvector" {
  source = "./aws-aurora"

  workspace_name     = data.coder_workspace.me.name
  eks_cluster_name   = var.eks_cluster_name
  db_master_username = "dbadmin"
  db_master_password = "YourStrongPasswordHere1"
  database_name      = "mydb1"
  postgresql_version = var.postgresql_version
}

resource "coder_metadata" "pod_info" {
    count = data.coder_workspace.me.start_count
    resource_id = kubernetes_deployment.dev[0].id
    daily_cost = local.cost
}
