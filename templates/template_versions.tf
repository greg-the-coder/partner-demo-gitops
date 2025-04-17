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

// Provider populated from environment variables
provider "coderd" {
    url   = "${var.coder_url}"
    token = "${var.coder_token}"
}
resource "coderd_user" "coderGitOps" {
  username = "coderGitOps"
  name     = "Coder GitOps"
  email    = "GitOps@coder.com"
}

resource "coderd_template" "kubernetes-base" {
  name        = "kubernetes-base"
  display_name = "Kubernetes (Deployment) GitOps"
  description = "Provision Kubernetes Deployments as Coder workspaces."
  icon = "/icon/aws.svg"
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
  name        = "kubernetes-devcontainer"
  display_name = "Devcontainers (Kubernetes) GitOps"
  description = "Provision envbuilder pods as Coder workspaces"
  icon = "/icon/aws.svg"
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