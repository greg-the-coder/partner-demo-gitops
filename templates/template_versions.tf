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
  description = "Provision Kubernetes Deployments as Coder workspaces."
  display_name = "Kubernetes (Deployment) GitOps"
  versions = [{
    directory = "./kubernetes-base"
    active    = true
    # Version name is optional
    name = "GitOps-Deployment"
    tf_vars = [{
      name  = "namespace"
      value = "default4"
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