terraform {
  required_providers {
    coderd = {
      source = "coder/coderd"
    }
  }
}
// Provider populated from environment variables
provider "coderd" {
    url   = env("CODER_AGENT_URL")
    token = env("CODER_AGENT_TOKEN")
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
    groups = []
  }
}