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
