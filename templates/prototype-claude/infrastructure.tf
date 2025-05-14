provider "aws" {
  region = "us-east-2"
}

data "coder_parameter" "debug_mode" {
  type        = "bool"
  name        = "Debug mode"
  icon        = "/emojis/1f41b.png"
  order       = 999
  default     = false
  description = "Launch directly into the VM, not the dev container"
  mutable     = true
}

locals {
  availability_zone = "us-east-2b"
  # See AMIs here: https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Images:visibility=owned-by-me;v=3;$case=tags:false%5C,client:false;$regex=tags:false%5C,client:false
  #ami_id               = "ami-04f093e9b5bf94f4a" #demo-ami-2
  ami_id = "ami-0171520e335263d60" # ms-universal-container
  iam_instance_profile_name = "ec2-claude-code-bedrock"
  volume_size = 64
  volume_type = "gp3"
  hostname   = lower(data.coder_workspace.me.name)
  tags = {
    Name = "coder-${data.coder_workspace.me.name}"
    Coder_Provisioned = "true"
    Owner = data.coder_workspace_owner.me.name
    Coder_Agent_Token = try(coder_agent.dev[0].token, "")
    Coder_Agent_URL = try(data.coder_workspace.me.access_url, "")
  }
}


variable "aws_access_key" {
}

variable "aws_secret_access_key" {
  sensitive = true
}

data "cloudinit_config" "user_data" {
  gzip          = false
  base64_encode = false

  boundary = "//"

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = file("${path.module}/cloud-init/cloud-config.yaml")
  }

  part {
    filename     = "userdata.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/cloud-init/userdata.sh", {
      hostname = local.hostname
      agent_token = try(coder_agent.dev[0].token, "")
      debug_mode = data.coder_parameter.debug_mode.value
      region = "us-east-2"
      init_script = try(coder_agent.dev[0].init_script, "")
    })
  }
  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      write_files = [
        {
          path        = "/usr/local/bin/stream-logs.sh"
          content     = file("${path.module}/cloud-init/stream-logs.sh")
          permissions = "0755"
        }
      ]
    })
  }
}

resource "aws_instance" "dev" {
  ami               = local.ami_id 
  availability_zone = local.availability_zone
  instance_type     = "t3.medium"

  user_data_base64 = base64encode(data.cloudinit_config.user_data.rendered)
  iam_instance_profile = local.iam_instance_profile_name

  root_block_device {
    volume_size = local.volume_size
    volume_type = local.volume_type
  }

  tags = local.tags

  metadata_options {
    instance_metadata_tags = "enabled"
  }

  # For now, set it to default SG. No need to expose the SSH port, already accessible over Session Manager
  # https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html
  # key_name          = data.coder_parameter.debug_mode.value == "true" ? "ben-aidemo" : null
  # security_groups   = data.coder_parameter.debug_mode.value == "true" ? ["ssh"] : []

  
  lifecycle {
    ignore_changes = [ ami ]
  }
}

resource "aws_ec2_instance_state" "dev" {
  instance_id = aws_instance.dev.id
  state       = data.coder_workspace.me.start_count != 0 ? "running" : "stopped"
}

resource "coder_metadata" "vm_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = aws_instance.dev.id
  daily_cost  = 1
}