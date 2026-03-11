terraform {
    required_providers {
        kubernetes = {
            source = "hashicorp/kubernetes"
            version = "2.37.1"
        }
        coder = {
            source  = "coder/coder"
            version = ">= 2.13"
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
  default     = "coder"
}

locals {
  home_dir = "/home/coder"
  bin_path = "/home/coder/.local/bin:/home/coder/bin:/home/coder/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
}

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
  default   = 2
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
  default   = 30
  order     = 3
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

locals {
    cost = 2
}

resource "coder_agent" "dev" {
    arch = "amd64"
    os = "linux"
    dir = local.home_dir
    env = {
        PATH = local.bin_path
    }
    display_apps {
        vscode          = false
        vscode_insiders = false
        web_terminal    = true
        ssh_helper      = false
    }
    startup_script_behavior = "blocking"
    startup_script = <<-EOT
    set -e
    
    # Updated ssh known hosts
    mkdir -p ~/.ssh
    ssh-keyscan -t ed25519,rsa github.com >> ~/.ssh/known_hosts 2>/dev/null
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/known_hosts

    # Create persistent bin directory
    mkdir -p $HOME/bin
    mkdir -p $HOME/.local/bin
    
    # Update PATH for current session
    export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.npm-global/bin:$PATH"
    
    sudo apt update
    sudo apt install -y curl unzip gnupg dirmngr

    # install AWS CLI to persistent location
    if ! command -v aws &> /dev/null; then
      echo "Installing AWS CLI..."
      cd $HOME
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip -q awscliv2.zip
      
      # Install to home directory instead of system-wide
      ./aws/install --install-dir $HOME/.local/aws-cli --bin-dir $HOME/.local/bin
      
      # Verify installation
      aws --version
      
      # Cleanup
      rm -rf aws awscliv2.zip
      
      echo "AWS CLI installation completed"
    else
      echo "AWS CLI is already installed"
      aws --version
    fi

    # install Node.js and npm (required for CDK and Kiro CLI)
    if ! command -v node &> /dev/null; then
      echo "Installing Node.js..."
      # Add NodeSource repository for the latest LTS version
      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
      sudo apt-get install nodejs -y
      
      # Verify installation
      node -v
      npm -v
      
      echo "Node.js installation completed"
    else
      echo "Node.js is already installed"
      node -v
    fi

    # install AWS CDK to persistent location
    if ! command -v cdk &> /dev/null; then
      echo "Installing AWS CDK..."
      
      # Configure npm to use home directory for global packages
      mkdir -p $HOME/.npm-global
      npm config set prefix "$HOME/.npm-global"
      
      # Install AWS CDK to home directory
      npm install -g aws-cdk
      
      # Create symlink in bin directory
      ln -sf $HOME/.npm-global/bin/cdk $HOME/.local/bin/cdk
      
      # Verify CDK installation
      cdk --version
      
      echo "AWS CDK installation completed"
    else
      echo "AWS CDK is already installed"
      cdk --version
    fi

    # install Kiro CLI to persistent location
    if ! command -v kiro-cli &> /dev/null; then
      echo "Installing Kiro CLI..."
      curl -fsSL https://cli.kiro.dev/install | bash
      
      # Verify Kiro CLI installation
      kiro-cli version
      
      echo "Kiro CLI installation completed"
    else
      echo "Kiro CLI is already installed"
      kiro-cli version
    fi

    # Install uv (Python package manager) which includes uvx for MCP servers
    if [ ! -f "$HOME/.local/bin/uv" ]; then
      echo "Installing uv/uvx..."
      UV_UNMANAGED_INSTALL="$HOME/.local/bin" curl -LsSf https://astral.sh/uv/install.sh | sh
      echo "uv/uvx installation completed"
    else
      echo "uv/uvx is already installed"
    fi
    
    # Configure Kiro CLI MCP servers
    echo "Configuring Kiro CLI MCP servers..."
    mkdir -p $HOME/.kiro/settings
    
    # Create MCP configuration file
    export CODER_URL_CLEAN="$${CODER_URL%/}"
    export CODER_MCP_URL="$${CODER_URL_CLEAN}/api/experimental/mcp/http"

    cat > ~/.kiro/settings/mcp.json << EOF
    {
      "mcpServers": {
        "coder": {
          "url": "$CODER_MCP_URL",
          "headers": {
            "Authorization": "Bearer $CODER_SESSION_TOKEN"
          },
          "autoApprove": [
            "coder_workspace_edit_file",
            "coder_workspace_read_file",
            "coder_get_task_status",
            "coder_workspace_write_file",
            "coder_workspace_ls",
            "coder_workspace_bash",
            "coder_get_task_logs",
            "coder_list_templates",
            "coder_create_task",
            "coder_get_authenticated_user",
            "coder_delete_task",
            "coder_send_task_input",
            "coder_list_workspaces",
            "coder_workspace_edit_files",
            "coder_workspace_list_apps",
            "coder_workspace_port_forward",
            "coder_create_workspace_build",
            "coder_template_version_parameters"
          ]
        }
      }
    }
    EOF

    echo "Kiro CLI MCP configuration completed"
    
    # Configure workspace trust settings for Kiro IDE
    echo "Configuring Kiro IDE workspace trust..."
    mkdir -p $HOME/.local/share/code-server/User
    
    # Create or update settings.json to trust the home folder
    cat > $HOME/.local/share/code-server/User/settings.json <<'SETTINGS_EOF'
    {
      "security.workspace.trust.enabled": true,
      "security.workspace.trust.startupPrompt": "never",
      "security.workspace.trust.emptyWindow": false,
      "security.workspace.trust.untrustedFiles": "open"
    }
    SETTINGS_EOF
    
    # Add trusted folders configuration
    mkdir -p $HOME/.kiro/settings
    cat > $HOME/.kiro/settings/trusted-workspaces.json <<'TRUST_EOF'
    {
      "trustedFolders": [
        "/home/coder"
      ]
    }
    TRUST_EOF
    
    echo "Kiro IDE workspace trust configuration completed"
    
    #Symlink Coder Agent
    ln -sf /tmp/coder.*/coder "$CODER_SCRIPT_BIN_DIR/coder" 

    EOT

}

module "coder-login" {
    source   = "registry.coder.com/coder/coder-login/coder"
    version  = "1.1.0"
    agent_id = coder_agent.dev.id
}

module "code-server" {
    source   = "registry.coder.com/coder/code-server/coder"
    version  = "1.3.1"
    agent_id       = coder_agent.dev.id
    folder         = local.home_dir
    subdomain = false
    order = 0
}

module "kiro" {
    source   = "registry.coder.com/coder/kiro/coder"
    version  = "1.1.0"
    agent_id = coder_agent.dev.id
    order = 1
}
# Prompt the user for the git repo URL
data "coder_parameter" "git_repo" {
  name         = "git_repo"
  display_name = "Git repository"
  default      = "https://github.com/greg-the-coder/aws-rag-prototyping.git"
}

# Default git configuration to Coder user credentials
module "git-config" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/git-config/coder"
  version  = "1.0.33"
  agent_id = coder_agent.dev.id
}

# Clone the repository 
module "git-clone" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/git-clone/coder"
  version  = "1.2.3"
  agent_id = coder_agent.dev.id
  url      = data.coder_parameter.git_repo.value
}

resource "coder_app" "kiro_cli" {
    agent_id     = coder_agent.dev.id
    slug         = "kiro-auth"
    display_name = "Kiro CLI"
    icon         = "${data.coder_workspace.me.access_url}/icon/kiro.svg"
    command      = "kiro-cli"
    share        = "owner"
    order        = 2
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
        storage = "${data.coder_parameter.disk_size.value}Gi"
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
