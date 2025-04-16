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
  name     = "Coder GitOps Admin"
  email    = "coderGitOps@coder.com"
}

resource "coderd_template" "kubernetes-base" {
  name        = "Kubernetes (Deployment)-GitOps"
  description = "Provision Kubernetes Deployments as Coder workspaces."
  versions = [
    {
      name        = "stable-test1"
      description = "The stable version of the template."
      directory   = "./kubernetes-base"
    }
  ]
  acl = {
    users = [{
      id   = coderd_user.coderGitOps.id
      role = "admin"
    }]
    groups = []
  }
}