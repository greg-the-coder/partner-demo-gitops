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

resource "coderd_template" "prototype-agentic-claude" {
  name        = "prototype-agentic-claude"
  display_name = "Prototype Anything with Claude Code"
  description = "Create any website, CLI tool, or package using Claude Code."
  icon = "/icon/claude.svg"
  versions = [{
    directory = "./prototype-claude"
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

}