terraform {
  required_version = ">= 1.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 0.17"
    }
  }
}

variable "agent_id" {
  type        = string
  description = "The ID of a Coder agent."
}

resource "coder_script" "install-vscode" {
  agent_id     = var.agent_id
  display_name = "Install VS Code"
  icon         = "/icon/vscode.svg"
  run_on_start = true
  script = templatefile("${path.module}/install.ps1", {})
}