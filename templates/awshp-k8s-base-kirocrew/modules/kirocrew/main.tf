terraform {
  required_version = ">= 1.9"
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.13"
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Input variables
# ──────────────────────────────────────────────────────────────────────────────

variable "agent_id" {
  type        = string
  description = "The ID of the Coder agent in the workspace."
}

variable "port" {
  type        = number
  description = "Port the KiroCrew gateway listens on inside the workspace."
  default     = 8899
}

variable "log_path" {
  type        = string
  description = "Path to write the KiroCrew gateway log."
  default     = "/tmp/kirocrew-gateway.log"
}

variable "install_prefix" {
  type        = string
  description = "Directory where Kiro CLI and KiroCrew are installed."
  default     = "/home/coder/.local/bin"
}

variable "order" {
  type        = number
  description = "Display order for the KiroCrew app in the Coder dashboard."
  default     = null
}

variable "group" {
  type        = string
  description = "App group for the KiroCrew app in the Coder dashboard."
  default     = null
}

variable "share" {
  type    = string
  default = "owner"
  validation {
    condition     = contains(["owner", "authenticated", "public"], var.share)
    error_message = "share must be 'owner', 'authenticated', or 'public'."
  }
}

variable "subdomain" {
  type        = bool
  description = "Expose the KiroCrew dashboard on its own subdomain (requires wildcard DNS)."
  default     = false
}

variable "open_in" {
  type    = string
  default = "slim-window"
  validation {
    condition     = contains(["tab", "slim-window"], var.open_in)
    error_message = "open_in must be 'tab' or 'slim-window'."
  }
}

variable "use_cached" {
  type        = bool
  description = "Skip re-downloading Kiro CLI / KiroCrew if already present."
  default     = true
}

# Optional: pass a fully-rendered MCP JSON string to overwrite mcp.json.
# Leave empty to keep whatever mcp.json was already written by the startup script.
variable "extra_mcp_json" {
  type        = string
  description = "Optional JSON string to write/merge into ~/.kiro/settings/mcp.json."
  default     = ""
}

# Optional: AWS Builder ID external auth token, injected from a Coder
# external-auth data source at the template level.
variable "aws_builder_id_token" {
  type        = string
  description = "AWS Builder ID access token from coder_external_auth. Leave empty when not using Builder ID auth."
  default     = ""
  sensitive   = true
}

variable "allowed_origins" {
  type        = string
  description = <<-EOT
    Comma-separated extra origins the KiroCrew gateway should trust in its
    Host/Origin allowlist (its DNS-rebinding guard). The gateway only accepts
    loopback hosts by default, so a Coder reverse-proxy request arrives with a
    non-loopback Host and is rejected ("Host header not allowed."). Set this to
    the Coder access URL origin (path-based apps) and/or the app's subdomain
    origin (subdomain apps), e.g. "https://coder.example.com". Passed through to
    KIROCREW_CORS_ORIGINS.
  EOT
  default     = ""
}

# ──────────────────────────────────────────────────────────────────────────────
# Locals
# ──────────────────────────────────────────────────────────────────────────────

locals {
  extra_mcp_b64        = var.extra_mcp_json != "" ? base64encode(var.extra_mcp_json) : ""
  aws_token_b64        = var.aws_builder_id_token != "" ? base64encode(var.aws_builder_id_token) : ""
}

# ──────────────────────────────────────────────────────────────────────────────
# Startup script: install + launch KiroCrew gateway
# ──────────────────────────────────────────────────────────────────────────────

resource "coder_script" "kirocrew" {
  agent_id         = var.agent_id
  display_name     = "KiroCrew Gateway"
  icon             = "/icon/kiro.svg"
  run_on_start     = true
  start_blocks_login = false

  script = templatefile("${path.module}/run.sh", {
    INSTALL_PREFIX   = var.install_prefix
    PORT             = var.port
    LOG_PATH         = var.log_path
    USE_CACHED       = var.use_cached
    EXTRA_MCP_B64    = local.extra_mcp_b64
    AWS_TOKEN_B64    = local.aws_token_b64
    ALLOWED_ORIGINS  = var.allowed_origins
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# Coder app: KiroCrew dashboard
# ──────────────────────────────────────────────────────────────────────────────

resource "coder_app" "kirocrew" {
  agent_id     = var.agent_id
  slug         = "kirocrew"
  display_name = "KiroCrew"
  url          = "http://localhost:${var.port}/"
  icon         = "/icon/kiro.svg"
  subdomain    = var.subdomain
  share        = var.share
  order        = var.order
  group        = var.group
  open_in      = var.open_in

  healthcheck {
    url       = "http://localhost:${var.port}/health"
    interval  = 5
    threshold = 6
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Outputs
# ──────────────────────────────────────────────────────────────────────────────

output "kirocrew_url" {
  value       = "http://localhost:${var.port}/"
  description = "Local URL for the KiroCrew gateway."
}
