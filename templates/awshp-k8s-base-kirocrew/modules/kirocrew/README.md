---
display_name: KiroCrew
description: Install KiroCrew gateway and surface the KiroCrew dashboard as a Coder app, with optional AWS Builder ID / IAM Identity Center auth.
icon: ../../../../.icons/kiro.svg
verified: false
tags: [ai, kiro, kirocrew, aws, mcp]
---

# kirocrew

Installs the **KiroCrew gateway** inside a Coder workspace and adds a
**KiroCrew** button to the Coder dashboard. Optionally injects additional MCP
server configuration and wires up an AWS Builder ID (or IAM Identity Center)
access token obtained via Coder's external-auth system.

## Minimal usage

```hcl
module "kirocrew" {
  source   = "./modules/kirocrew"
  agent_id = coder_agent.dev.id
}
```

## With AWS Builder ID auth

Configure the Coder server with an AWS Builder ID / IAM Identity Center
external-auth provider (see the template's `external-auth.md`), then pass the
token through:

```hcl
data "coder_external_auth" "aws_builder_id" {
  id = "aws-builder-id"
}

module "kirocrew" {
  source               = "./modules/kirocrew"
  agent_id             = coder_agent.dev.id
  aws_builder_id_token = data.coder_external_auth.aws_builder_id.access_token
}
```

## With extra MCP servers

```hcl
module "kirocrew" {
  source         = "./modules/kirocrew"
  agent_id       = coder_agent.dev.id
  extra_mcp_json = jsonencode({
    mcpServers = {
      pulumi = {
        type = "http"
        url  = "https://mcp.ai.pulumi.com/mcp"
        headers = {
          Authorization = "Bearer ${var.pulumi_token}"
        }
      }
    }
  })
}
```

## Headless Kiro authentication (`KIRO_API_KEY`)

Kiro CLI 2.0+ supports **headless mode**: when the `KIRO_API_KEY` environment
variable is present, `kiro-cli` skips the browser login entirely. The KiroCrew
gateway spawns `kiro-cli` as its agent runtime, so if `KIRO_API_KEY` is in the
gateway's environment, the crew agent authenticates non-interactively — no
Builder ID / SSO prompt.

The module does **not** take the key as a Terraform input (that would put the
secret in state). Instead, provide it per-user via a **Coder user secret** with
an `--env KIRO_API_KEY` target — Coder injects it into the workspace agent (and
therefore the gateway) at start, and it takes precedence over template env vars:

```bash
# Run once per developer. stdin keeps the key out of shell history / argv.
printf %s "$YOUR_KIRO_API_KEY" | coder secret create kiro-api-key \
  --description "Kiro CLI headless auth" \
  --env KIRO_API_KEY
# then restart the workspace
```

Notes:
- API keys require a Kiro Pro/Pro+/Pro Max/Power subscription; enterprise-managed
  accounts need an admin to enable API-key generation (governance). Generate and
  rotate keys at <https://app.kiro.dev>.
- Per-user secrets fit Kiro's per-user key model: crew activity is attributed to
  that user and honors their governance policies.
- Enable Coder database encryption so secret values are encrypted at rest.
- Rotating/deleting the Coder secret does **not** revoke the Kiro key — rotate it
  in the Kiro portal. Changes take effect on the next workspace restart.
- The gateway logs `Headless Kiro auth: KIRO_API_KEY detected` on start when the
  key is present (see the "KiroCrew Gateway" script log).

## Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `agent_id` | string | **required** | Coder agent ID |
| `port` | number | `8899` | Gateway port |
| `log_path` | string | `/tmp/kirocrew-gateway.log` | Log file path |
| `install_prefix` | string | `/home/coder/.local/bin` | Installation directory |
| `use_cached` | bool | `true` | Skip reinstall if already present |
| `order` | number | `null` | Dashboard app display order |
| `group` | string | `null` | Dashboard app group |
| `share` | string | `owner` | App visibility (`owner`/`authenticated`/`public`) |
| `subdomain` | bool | `false` | Expose on subdomain vs path |
| `open_in` | string | `slim-window` | `tab` or `slim-window` |
| `extra_mcp_json` | string | `""` | JSON to merge into `mcp.json` |
| `aws_builder_id_token` | string | `""` | AWS Builder ID access token (sensitive) |
| `slug` | string | `kirocrew` | Base slug for the visible KiroCrew app tile |
| `redirect_port` | number | `8898` | Loopback port for the token-minting redirector that fronts the dashboard app |
| `allowed_origins` | string | `""` | Extra comma-separated origins to trust in the gateway Host/Origin allowlist (the module already trusts the dashboard app origin) |

## Access model (self-authenticating tile)

The module exposes the dashboard through a **self-authenticating** Coder app:
the visible `kirocrew` tile points at a loopback redirector that mints a
short-lived token and 302-redirects to a hidden `<slug>-dashboard` subdomain app
serving the SPA. Clicking the tile lands on an already-authenticated dashboard —
no manual `kirocrew token`. The module derives the dashboard subdomain origin
from its own `coder_workspace`/owner data sources, trusts it in the gateway's
Host allowlist, and sets `dashboard.url` so token cookies bind to that origin.
