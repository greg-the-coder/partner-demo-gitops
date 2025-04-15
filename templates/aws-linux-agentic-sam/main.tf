terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
}
provider "aws" {
  region = data.coder_parameter.region.value
}
#### Update to Workshop IAM Instance Profile
data "aws_iam_instance_profile" "vm_instance_profile" {
  name  = "gtc-demo-aws-workshop-access"
}

### Inject Claude-Code Agent into Workspace
variable "anthropic_api_key" {
  type        = string
  description = "The Anthropic API key"
  sensitive   = true
}

module "coder-login" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/modules/coder-login/coder"
  version  = "1.0.30"
  agent_id = coder_agent.dev[count.index].id
}

data "coder_parameter" "ai_prompt" {
  type        = "string"
  name        = "AI Prompt"
  default     = ""
  description = "Write a prompt for Claude Code"
  mutable     = true
}

# Set the prompt and system prompt for Claude Code via environment variables
module "claude-code" {
  count               = data.coder_workspace.me.start_count
  source              = "registry.coder.com/modules/claude-code/coder"
  version             = "1.0.31"
  agent_id            = coder_agent.dev[count.index].id
  folder              = "/home/coder"
  install_claude_code = true
  claude_code_version = "0.2.57"

  # Enable experimental features
  experiment_use_screen   = true
  experiment_report_tasks = true
}

# aws ec2 describe-regions | jq -r '[.Regions[].RegionName] | sort'
data "coder_parameter" "region" {
  name         = "region"
  display_name = "Region"
  description  = "The region to deploy the workspace in."
  default      = "us-east-1"
  mutable      = false
  option {
    name  = "US East (N. Virginia)"
    value = "us-east-1"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US East (Ohio)"
    value = "us-east-2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US West (N. California)"
    value = "us-west-1"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
  option {
    name  = "US West (Oregon)"
    value = "us-west-2"
    icon  = "/emojis/1f1fa-1f1f8.png"
  }
}

data "coder_parameter" "instance_type" {
  name         = "instance_type"
  display_name = "Instance type"
  description  = "What instance type should your workspace use?"
  default      = "m7g.medium"
  mutable      = false
  option {
    name  = "1 vCPU, 4 GiB RAM"
    value = "m7g.medium"
  }
  option {
    name  = "2 vCPU, 8 GiB RAM"
    value = "m7g.large"
  }
  option {
    name  = "4 vCPU, 16 GiB RAM"
    value = "m7g.xlarge"
  }
}
data "coder_parameter" "instance_diskGB" {
  name         = "instance_diskGB"
  display_name = "Disk Size GB"
  description  = "What how much storage (GB) does your workspace need?"
  default      = "10"
  mutable      = false
  option {
    name  = "10 GB"
    value = "10"
  }
  option {
    name  = "20 GB"
    value = "20"
  }
  option {
    name  = "40 GB"
    value = "40"
  }
}

data "coder_workspace" "me" {
}
data "coder_workspace_owner" "me" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/*"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
   owners = ["099720109477"] # Canonical
}

resource "coder_agent" "dev" {
  count          = data.coder_workspace.me.start_count
  arch           = "arm64"
  auth           = "aws-instance-identity"
  os             = "linux"
  env = {
    CODER_MCP_CLAUDE_API_KEY       = var.anthropic_api_key # or use a coder_parameter
    CODER_MCP_CLAUDE_TASK_PROMPT   = data.coder_parameter.ai_prompt.value
    CODER_MCP_APP_STATUS_SLUG      = "claude-code"
    CODER_MCP_CLAUDE_SYSTEM_PROMPT = <<-EOT
      You are a helpful assistant that can help with code.
    EOT
  }

  startup_script = <<-EOT
    set -e
    # Update/patch OS and install screen to support Agentic AI flow
    sudo apt update -y
    sudo apt install screen

    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server --version 4.11.0
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &

    # install AWS CLI
    if [ ! -d "aws" ]; then
      sudo apt install -y curl unzip
      curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      aws --version
      rm awscliv2.zip
    fi

    # install AWS SAM
    if [ ! -d "sam-installation" ]; then
      sudo apt install -y python3 python3-pip unzip
      curl -Lo aws-sam-cli-linux-arm64.zip https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-arm64.zip
      mkdir sam-installation
      unzip aws-sam-cli-linux-arm64.zip -d sam-installation
      sudo ./sam-installation/install
      sam --version
      rm aws-sam-cli-linux-arm64.zip
    fi
    
    # install Amazon Q Developer CLI
    # curl --proto '=https' --tlsv1.2 -sSf https://desktop-release.q.us-east-1.amazonaws.com/latest/amazon-q.appimage -o amazon-q.appimage
    # chmod +x amazon-q.appimage
    # sudo dnf check-update
    # sudo dnf install fuse2
    # verify q cli install
    # q doctor

  EOT
  
  metadata {
    key          = "cpu"
    display_name = "CPU Usage"
    interval     = 5
    timeout      = 5
    script       = "coder stat cpu"
  }
  metadata {
    key          = "memory"
    display_name = "Memory Usage"
    interval     = 5
    timeout      = 5
    script       = "coder stat mem"
  }
  metadata {
    key          = "disk"
    display_name = "Disk Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large filesystems
    script       = "coder stat disk --path $HOME"
  }
}
resource "coder_app" "code-server" {
  count        = data.coder_workspace.me.start_count
  agent_id     = coder_agent.dev[0].id
  slug         = "code-server"
  display_name = "code-server"
  url          = "http://localhost:13337/?folder=/home/coder"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}

locals {
  linux_user = "coder"
  user_data  = <<-EOT
  Content-Type: multipart/mixed; boundary="//"
  MIME-Version: 1.0

  --//
  Content-Type: text/cloud-config; charset="us-ascii"
  MIME-Version: 1.0
  Content-Transfer-Encoding: 7bit
  Content-Disposition: attachment; filename="cloud-config.txt"

  #cloud-config
  cloud_final_modules:
  - [scripts-user, always]
  hostname: ${lower(data.coder_workspace.me.name)}
  users:
  - name: ${local.linux_user}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

  --//
  Content-Type: text/x-shellscript; charset="us-ascii"
  MIME-Version: 1.0
  Content-Transfer-Encoding: 7bit
  Content-Disposition: attachment; filename="userdata.txt"

  #!/bin/bash
  sudo -u ${local.linux_user} sh -c '${try(coder_agent.dev[0].init_script, "")}'
  --//--
  EOT
}

resource "aws_instance" "dev" {
  ami               = data.aws_ami.ubuntu.id
  availability_zone = "${data.coder_parameter.region.value}a"
  instance_type     = data.coder_parameter.instance_type.value
  iam_instance_profile = data.aws_iam_instance_profile.vm_instance_profile.name

  user_data = local.user_data
  tags = {
    Name = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
    # Required if you are using our example policy, see template README
    Coder_Provisioned = "true"
  }
  lifecycle {
    ignore_changes = [ami]
  }
  root_block_device {
    volume_size = "${data.coder_parameter.instance_diskGB.value}"
  }
}

resource "coder_metadata" "workspace_info" {
  resource_id = aws_instance.dev.id
  item {
    key   = "region"
    value = data.coder_parameter.region.value
  }
  item {
    key   = "instance type"
    value = aws_instance.dev.instance_type
  }
  item {
    key   = "disk"
    value = "${aws_instance.dev.root_block_device[0].volume_size} GiB"
  }
}

resource "aws_ec2_instance_state" "dev" {
  instance_id = aws_instance.dev.id
  state       = data.coder_workspace.me.transition == "start" ? "running" : "stopped"
}

