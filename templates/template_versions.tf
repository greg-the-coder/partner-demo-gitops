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

###########################################################
# Maintain Coder Template Resources in this Section
###########################################################

#resource "coderd_template" "awshp-k8s-with-claude-code" {
#  name        = "awshp-k8s-base-claudecode"
#  display_name = "AWS Workshop - Kubernetes with Claude Code"
#  description = "Provision Kubernetes Deployments as Coder workspaces with Anthropic Claude Code."
#  icon = "/icon/k8s.png"
#  versions = [{
#    directory = "./awshp-k8s-with-claude-code"
#    active    = true
#    # Version name is optional
#    name = var.coder_gitsha
#    tf_vars = [{
#      name  = "namespace"
#      value = "coder"
#    }]
#  }]
#}

resource "coderd_template" "awshp-k8s-tasks-with-cc-jupyter" {
  name        = "awshp-k8s-tasks-with-cc-jupyter"
  display_name = "AWS Workshop - Kubernetes with Claude Code + Jupyter lab"
  description = "Provision Kubernetes Deployments as Coder workspaces with Anthropic Claude Code and Jupyter lab."
  icon = "/icon/k8s.png"
  versions = [{
    directory = "./awshp-k8s-tasks-with-cc-jupyter"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
    tf_vars = [{
      name  = "namespace"
      value = "coder"
    }]
  }]
}

#resource "coderd_template" "awshp-linux-q-base" {
#  name        = "awshp-linux-q-base"
#  display_name = "AWS Workshop - EC2 (Linux) Q Developer"
#  description = "Provision AWS EC2 VMs as Q Developer enabled Coder workspaces"
#  icon = "/icon/aws.png"
#  versions = [{
#    directory = "./awshp-linux-q-base"
#    active    = true
#    # Version name is optional
#    name = var.coder_gitsha
#    tf_vars = [{
#      name  = "aws_iam_profile"
#      value = "coder-workshop-ec2-workspace-profile"
#    }]
#  }]
#}

resource "coderd_template" "awshp-linux-atx-base" {
  name        = "awshp-linux-atx-base"
  display_name = "AWS Workshop - EC2 (Linux) Transform CLI"
  description = "Provision AWS EC2 VMs as an AWS Transform enabled Coder workspaces"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./awshp-linux-atx-base"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
    tf_vars = [{
      name  = "aws_iam_profile"
      value = "coder-workshop-ec2-workspace-profile"
    }]
  }]
}

#resource "coderd_template" "awshp-linux-sam" {
#  name        = "awshp-linux-sam"
#  display_name = "AWS Workshop - EC2 (Linux) SAM"
#  description = "Provision AWS EC2 ARM64 VMs as Serverless Development Coder workspaces"
#  icon = "/icon/aws.png"
#  versions = [{
#    directory = "./awshp-linux-sam"
#    active    = true
#    # Version name is optional
#    name = var.coder_gitsha
#    tf_vars = [{
#      name  = "aws_iam_profile"
#      value = "coder-workshop-ec2-workspace-profile"
#    }]
#  }]
#}

#resource "coderd_template" "awshp-windows-dcv" {
#  name        = "awshp-windows-dcv"
#  display_name = "AWS Workshop EC2 (Windows) DCV"
#  description = "Provision AWS EC2 Windows VMs as Coder workspaces accessible via browser using Amazon DCV"
#  icon = "/icon/aws.png"
#  versions = [{
#    directory = "./awshp-windows-dcv"
#    active    = true
#    # Version name is optional
#    name = var.coder_gitsha
#  }]
#}

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
}

#resource "coderd_template" "kubernetes-with-amazon-q" {
#  name        = "kubernetes-base-amazonq"
#  display_name = "Kubernetes with Amazon Q"
#  description = "Provision Kubernetes Deployments as Coder workspaces with Amazon Q."
#  icon = "/icon/k8s.png"
#  versions = [{
#    directory = "./kubernetes-with-amazon-q"
#    active    = true
#    # Version name is optional
#    name = var.coder_gitsha
#    tf_vars = [{
#      name  = "namespace"
#      value = "coder"
#    },
#    {
#      name  = "amazon_q_auth_tarball"
#      value = "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"
#    }]
#  }]
#}

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
}

#resource "coderd_template" "kubernetes-awsrag-with-claude-code" {
#  name        = "kubernetes-awsrag-claudecode"
#  display_name = "Kubernetes AWS RAG Prototyping with Claude Code"
#  description = "Provision Kubernetes Deployments as Coder workspaces with Anthropic Claude Code for AWS RAG prototyping."
#  icon = "/icon/k8s.png"
#  versions = [{
#    directory = "./kubernetes-awsrag-with-claude-code"
#    active    = true
#    # Version name is optional
#    name = var.coder_gitsha
#    tf_vars = [{
#      name  = "namespace"
#      value = "coder"
#    },
#    {
#      name  = "eks_cluster_name"
#      value = "gtc-test-podid-eks"
#    }]
#  }]
#}

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
}

resource "coderd_template" "aws-linux-ec2-container" {
  name        = "aws-linux-ec2-container"
  display_name = "AWS EC2 (Linux) Container Development"
  description = "Provision AWS EC2 VMs as Coder workspaces for Container Development"
  icon = "/icon/aws.png"
  versions = [{
    directory = "./aws-linux-ec2-container"
    active    = true
    # Version name is optional
    name = var.coder_gitsha
  }]
}

