---
display_name: Kubernetes with Kiro CLI
description: Kubernetes workspace with Kiro CLI, AWS development tools, and MCP server support
icon: ../../../site/static/icon/k8s.png
maintainer_github: coder
verified: true
tags: [kubernetes, container, kiro, aws, mcp, ai]
---

# Kubernetes Workspace with Kiro CLI

A Kubernetes-based Coder template featuring Kiro CLI with Model Context Protocol (MCP) server support, AWS development tools, and persistent storage for cloud-native development.

## Prerequisites

### Infrastructure

**Kubernetes Cluster**: Requires an existing Kubernetes cluster with Coder deployed

**Container Image**: Uses [codercom/enterprise-base:ubuntu image](https://github.com/coder/enterprise-images/tree/main/images/base)

### Authentication

This template authenticates using a `~/.kube/config`, if present on the server, or via built-in authentication if the Coder provisioner is running on Kubernetes with an authorized ServiceAccount.

### Kiro CLI Integration

This template includes Kiro CLI with Model Context Protocol (MCP) server support:
- AI-powered development assistant via command line and web UI
- Ready for MCP server configuration
- Workspace trust pre-configured for seamless IDE integration
- uv/uvx installed for Python-based MCP servers

## Architecture

This template provisions:

- **Kubernetes Deployment**: Ephemeral pod with Coder agent
- **Persistent Volume Claim**: 30GB default for `/home/coder`
- **Coder Agent**: With custom PATH configuration
- **Development Tools**: All installed to persistent storage

When the workspace restarts, the pod is recreated but all tools in the home directory persist, including:
- Kiro CLI in `~/.local/bin`
- AWS CLI in `~/.local/aws-cli`
- AWS CDK in `~/.npm-global`
- Node.js packages and configurations

## Features

### Kiro Integration
- **Kiro CLI**: Latest version with full MCP support
- **Kiro IDE**: Kiro IDE integration
- **MCP Ready**: uv/uvx and Node.js pre-installed for MCP servers
- **Workspace Trust**: Auto-configured for `/home/coder`
- **Authentication App**: One-click Kiro CLI authentication

### Development Environment
- **code-server**: VS Code in the browser 
- **Web Terminal**: Direct terminal access
- **Coder Login**: Integrated authentication module

### Pre-installed Tools (Persistent)

All tools are installed to `/home/coder` during first startup and persist across restarts:

#### AWS Development Stack
- **AWS CLI v2**: Installed to `~/.local/aws-cli` with binaries in `~/.local/bin`
- **AWS CDK**: Installed to `~/.npm-global` with binaries in `~/.local/bin`
- **Node.js 20.x LTS**: System-wide installation for CDK and MCP servers

#### Python & MCP Support
- **uv/uvx**: Python package manager for MCP servers
- **npm**: Node.js package manager for JavaScript-based MCP servers

#### System Utilities
- **curl, unzip**: Download and archive utilities
- **gnupg, dirmngr**: GPG key management

## MCP Server Configuration

### Setting Up MCP Servers

The template creates the MCP configuration directory at `~/.kiro/settings/` but does not pre-configure any servers. You can add MCP servers manually or through the Kiro CLI.

#### Manual Configuration

Create or edit `~/.kiro/settings/mcp.json`:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "command-to-run",
      "args": ["arg1", "arg2"]
    }
  }
}
```

#### Example MCP Server Configurations

**1. Pulumi MCP Server (HTTP-based)**
```json
{
  "mcpServers": {
    "pulumi": {
      "type": "http",
      "url": "https://mcp.ai.pulumi.com/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_PULUMI_TOKEN"
      }
    }
  }
}
```

**2. LaunchDarkly MCP Server (npx-based)**
```json
{
  "mcpServers": {
    "LaunchDarkly": {
      "command": "npx",
      "args": [
        "-y", 
        "--package", "@launchdarkly/mcp-server", 
        "--", "mcp", "start",
        "--api-key", "YOUR_LAUNCHDARKLY_KEY"
      ]
    }
  }
}
```

**3. Arize Tracing Assistant (uvx-based)**
```json
{
  "mcpServers": {
    "arize-tracing-assistant": {
      "command": "/home/coder/.local/bin/uvx",
      "args": ["arize-tracing-assistant@latest"]
    }
  }
}
```

**4. Custom Python MCP Server**
```json
{
  "mcpServers": {
    "my-python-server": {
      "command": "/home/coder/.local/bin/uvx",
      "args": ["my-mcp-package@latest"]
    }
  }
}
```

### Using Kiro CLI to Configure MCP Servers

Kiro CLI may provide commands to add MCP servers. Check the latest documentation:

```bash
# Example (check Kiro CLI docs for actual commands)
kiro-cli mcp add <server-name>
```

## Parameters

### Configurable Resources
- **CPU cores**: 2-8 cores (default: 2)
- **Memory**: 4-16 GB (default: 4 GB)
- **PVC storage size**: 10-50 GB (default: 30 GB)

### Configuration
- **Namespace**: Default `coder` (configurable)

## Usage

### Getting Started

1. **Create Workspace**: Deploy from this template
2. **Authenticate Kiro**: Click the "Kiro CLI" app button to authenticate
3. **Configure MCP Servers**: Add desired MCP servers to `~/.kiro/settings/mcp.json`
4. **Access Development Tools**: 
   - Open code-server for VS Code experience
   - Use Kiro web UI for AI assistance
   - Access terminal for CLI operations

### Kiro CLI Commands

After authentication, use Kiro from the terminal:

```bash
# Start an AI chat session
kiro-cli chat

# Get help
kiro-cli --help

# Check version
kiro-cli version
```

### AWS Development

Pre-configured AWS tools for cloud development:

```bash
# AWS CLI
aws --version
aws s3 ls

# AWS CDK
cdk --version
cdk init app --language typescript
cdk deploy
```

### MCP Server Usage Examples

Once you've configured MCP servers, you can use them through Kiro CLI:

```bash
# Start a chat session and interact with MCP servers
kiro-cli chat

# Within the chat, you can query configured MCP servers:
# - "Show me Pulumi stack outputs"
# - "List LaunchDarkly feature flags"
# - "Analyze recent traces"
# - "Query my custom MCP server"
```

## Workspace Trust Configuration

The template automatically configures workspace trust for Kiro IDE:

**Settings Location**: `~/.local/share/code-server/User/settings.json`
```json
{
  "security.workspace.trust.enabled": true,
  "security.workspace.trust.startupPrompt": "never",
  "security.workspace.trust.emptyWindow": false,
  "security.workspace.trust.untrustedFiles": "open"
}
```

**Trusted Folders**: `~/.kiro/settings/trusted-workspaces.json`
```json
{
  "trustedFolders": ["/home/coder"]
}
```

## PATH Configuration

Custom PATH includes all persistent tool locations:

```
/home/coder/.local/bin
/home/coder/bin
/home/coder/.npm-global/bin
/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/sbin
/bin
```

## Advanced Configuration

### Adding MCP Servers via Startup Script

To pre-configure MCP servers for all workspaces, edit the startup script in `main.tf`:

```bash
# Uncomment and modify the MCP configuration section
cat > $HOME/.kiro/settings/mcp.json <<'MCP_EOF'
{
  "mcpServers": {
    "your-server": {
      "command": "npx",
      "args": ["-y", "your-mcp-package"]
    }
  }
}
MCP_EOF
```

### Custom Tool Installation

Add tools to the startup script for automatic installation:

```bash
# Example: Install additional CLI tool
if ! command -v your-tool &> /dev/null; then
  curl -L https://example.com/install.sh | bash
fi
```

### MCP Server Requirements

Different MCP servers have different requirements:

- **HTTP-based servers**: Require API tokens/keys
- **npx-based servers**: Use Node.js (pre-installed)
- **uvx-based servers**: Use Python uv (pre-installed)
- **Custom servers**: May require additional dependencies

## Coder Apps

The template provides these integrated apps:

1. **code-server** (order: 0): VS Code in browser
2. **Kiro** (order: 1): Kiro web interface
3. **Kiro CLI** (order: 2): Authentication and CLI access

## Notes

- **First Startup**: Takes 5-10 minutes for all tool installations
- **Subsequent Starts**: Fast startup as tools persist
- **MCP Servers**: Must be configured manually or via Kiro CLI
- **Workspace Trust**: Pre-configured for seamless Kiro experience
- **AWS Permissions**: Configure via Kubernetes ServiceAccount IAM role

## Troubleshooting

### Kiro CLI Authentication
```bash
# Check Kiro CLI installation
kiro-cli version

# Re-authenticate if needed
# Click the "Kiro CLI" app button in Coder dashboard
```

### MCP Server Issues
```bash
# Check MCP configuration
cat ~/.kiro/settings/mcp.json

# Test Node.js for npx-based MCP servers
node --version
npx --version

# Test uv/uvx for Python-based MCP servers
~/.local/bin/uv --version
~/.local/bin/uvx --version
```

### Tool Installation
```bash
# Verify AWS CLI
aws --version

# Verify AWS CDK
cdk --version

# Verify Kiro CLI
kiro-cli version
```

## MCP Server Resources

- **MCP Documentation**: Check the Model Context Protocol documentation
- **Kiro CLI Docs**: Refer to Kiro CLI documentation for MCP integration
- **Example Servers**: 
  - [Pulumi MCP](https://mcp.ai.pulumi.com/)
  - [LaunchDarkly MCP](https://www.npmjs.com/package/@launchdarkly/mcp-server)
  - Other MCP servers available via npm and PyPI

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.
