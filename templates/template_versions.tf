###########################################################
# Core Coder GitOps Provider, Resource & Variable definitions
###########################################################

terraform {
  required_providers {
    coderd = {
      source = "coder/coderd"
    }
  }
}

// Variables sourced from TF_VAR_<environment variables>
variable "coder_url" {
  type        = string
  description = "Coder deployment login url"
  default     = ""
}
variable "coder_token" {
  type        = string
  description = "Coder session token used to authenticate to deployment"
  default     = ""
}
variable "coder_gitsha" {
  type        = string
  description = "Git SHA to use in version name"
  default = ""  
}

provider "coderd" {
    url   = "${var.coder_url}"
    token = "${var.coder_token}"
}

resource "coderd_user" "coderGitOps" {
  username = "workshopGitOps"
  name     = "Coder Workshop GitOps"
  email    = "workshopGitOps@coder.com"
}

###########################################################
# Maintain Coder Template Resources in this Section
###########################################################

resource "coderd_template" "awshp-k8s-with-claude-code" {
  name        = "awshp-k8s-base-claudecode"
  display_name = "AWS Workshop - Kubernetes with Claude Code"
  description = "Provision Kubernetes Deployments as Coder workspaces with Anthropic Claude Code."
  icon = "/icon/k8s.png"
  versions = [{
    directory = "./awshp-k8s-with-claude-code"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
    tf_vars = [{
      name  = "namespace"
      value = "coder"
    }]
  }]
  acl = {
    users = [{
      id   = coderd_user.coderGitOps.id
      role = "admin"
    }]
    groups = []
  }
}

resource "coderd_template" "awshp-linux-q-base" {
  name        = "awshp-linux-q-base"
  display_name = "AWS Workshop - EC2 (Linux) Q Developer"
  description = "Provision AWS EC2 VMs as Q Developer enabled Coder workspaces"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./awshp-linux-q-base"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
    tf_vars = [{
      name  = "aws_iam_profile"
      value = "coder-workshop-ec2-workspace-role"
    }]
  }]
  acl = {
    users = [{
      id   = coderd_user.coderGitOps.id
      role = "admin"
    }]
    groups = []
  }
}

resource "coderd_template" "awshp-linux-sam" {
  name        = "awshp-linux-sam"
  display_name = "AWS Workshop - EC2 (Linux) SAM"
  description = "Provision AWS EC2 ARM64 VMs as Serverless Development Coder workspaces"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./awshp-linux-sam"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
    tf_vars = [{
      name  = "aws_iam_profile"
      value = "coder-workshop-ec2-workspace-role"
    }]
  }]
  acl = {
    users = [{
      id   = coderd_user.coderGitOps.id
      role = "admin"
    }]
    groups = []
  }
}

resource "coderd_template" "awshp-windows-dcv" {
  name        = "awshp-windows-dcv"
  display_name = "AWS Workshop EC2 (Windows) DCV"
  description = "Provision AWS EC2 Windows VMs as Coder workspaces accessible via browser using Amazon DCV"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./awshp-windows-dcv"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
  }]
}
