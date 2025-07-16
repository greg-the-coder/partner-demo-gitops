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
  username = "coderGitOps"
  name     = "Coder GitOps"
  email    = "GitOps@coder.com"
}

###########################################################
# Maintain Coder Template Resources in this Section
###########################################################

resource "coderd_template" "kubernetes-base" {
  name        = "kubernetes-base-gitops"
  display_name = "Kubernetes (Deployment) GitOps"
  description = "Provision Kubernetes Deployments as Coder workspaces."
  icon = "/icon/k8s.png"
  versions = [{
    directory = "./kubernetes-base"
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

resource "coderd_template" "kubernetes-devcontainer" {
  name        = "kubernetes-devcontainer-gitops"
  display_name = "Devcontainers (Kubernetes) GitOps"
  description = "Provision envbuilder pods as Coder workspaces"
  icon = "/icon/k8s.png"
  versions = [{
    directory = "./kubernetes-devcontainer"
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
resource "coderd_template" "kubernetes-with-amazon-q" {
  name        = "kubernetes-base-amazonq"
  display_name = "Kubernetes with Amazon Q"
  description = "Provision Kubernetes Deployments as Coder workspaces with Amazon Q."
  icon = "/icon/k8s.png"
  versions = [{
    directory = "./kubernetes-with-amazon-q"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
    tf_vars = [{
      name  = "namespace"
      value = "coder"
    },
    {
      name  = "amazon_q_auth_tarball"
      value = "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"
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

resource "coderd_template" "aws-devcontainer" {
  name        = "aws-devcontainer"
  display_name = "Devcontainers (AWS EC2 Linux)"
  description = "Provision envbuilder containers on AWS EC2 VMs as Coder workspaces"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./aws-devcontainer"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
  }]
  acl = {
    users = [{
      id   = coderd_user.coderGitOps.id
      role = "admin"
    }]
    groups = []
  }
}

resource "coderd_template" "aws-linux-agentic-sam" {
  name        = "aws-linux-agentic-sam-gitops"
  display_name = "AWS EC2 (Linux) Agentic SAM"
  description = "Provision AWS EC2 VM Coder Workspace for Agentic Serverless Development"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./aws-linux-agentic-sam"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
    tf_vars = [{
      name  = "anthropic_api_key"
      value = "default"
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

resource "coderd_template" "aws-linux-base" {
  name        = "aws-linux-base"
  display_name = "AWS EC2 (Linux)"
  description = "Provision AWS EC2 VMs as Coder workspaces"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./aws-linux-base"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
  }]
  acl = {
    users = [{
      id   = coderd_user.coderGitOps.id
      role = "admin"
    }]
    groups = []
  }
}

resource "coderd_template" "aws-linux-dlami" {
  name        = "aws-linux-dlami"
  display_name = "AWS EC2 (Linux) Deep Learning AMI"
  description = "Provision AWS Deep Learning AMI (ARM64) as Coder workspaces"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./aws-linux-dlami"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
  }]
  acl = {
    users = [{
      id   = coderd_user.coderGitOps.id
      role = "admin"
    }]
    groups = []
  }
}

resource "coderd_template" "aws-linux-q-base" {
  name        = "aws-linux-q-base"
  display_name = "AWS EC2 (Linux) Q Developer"
  description = "Provision AWS EC2 VMs as Q Developer enabled Coder workspaces"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./aws-linux-q-base"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
    tf_vars = [{
      name  = "aws_iam_profile"
      value = "gtc-demo-aws-workshop-access"
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

resource "coderd_template" "aws-linux-sam" {
  name        = "aws-linux-sam"
  display_name = "AWS EC2 (Linux) SAM"
  description = "Provision AWS EC2 ARM64 VMs as Serverless Development Coder workspaces"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./aws-linux-sam"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
  }]
  acl = {
    users = [{
      id   = coderd_user.coderGitOps.id
      role = "admin"
    }]
    groups = []
  }
}

resource "coderd_template" "aws-windows-dcv" {
  name        = "aws-windows-dcv"
  display_name = "AWS EC2 (Windows) DCV"
  description = "Provision AWS EC2 Windows VMs as Coder workspaces accessible via browser using Amazon DCV"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./aws-windows-dcv"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
  }]
  acl = {
    users = [{
      id   = coderd_user.coderGitOps.id
      role = "admin"
    }]
    groups = []
  }
}
