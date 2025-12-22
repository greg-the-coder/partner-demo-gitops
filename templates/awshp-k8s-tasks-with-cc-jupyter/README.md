---
display_name: Kubernetes with Claude Code
description: Provision Kubernetes Deployments with Claude Code AI assistant as Coder workspaces
icon: ../../../site/static/icon/k8s.png
maintainer_github: coder
verified: true
tags: [kubernetes, container, ai, claude]
---

# Remote Development on Kubernetes Pods with Claude Code

Provision Kubernetes Pods with integrated Claude Code AI assistant as [Coder workspaces](https://coder.com/docs/workspaces) with this example template.

<!-- TODO: Add screenshot -->

## Prerequisites

### Infrastructure

**Cluster**: This template requires an existing Kubernetes cluster

**Container Image**: This template uses the [codercom/enterprise-base:ubuntu image](https://github.com/coder/enterprise-images/tree/main/images/base) with some dev tools preinstalled. To add additional tools, extend this image or build it yourself.

### Authentication

This template authenticates using a `~/.kube/config`, if present on the server, or via built-in authentication if the Coder provisioner is running on Kubernetes with an authorized ServiceAccount. To use another [authentication method](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#authentication), edit the template.

### Claude Code Integration

This template includes Claude Code AI assistant integration that provides:
- AI-powered code generation and assistance
- Task automation based on user prompts
- Integration with AWS Bedrock for Claude models
- Automatic task reporting to Coder

## Architecture

This template provisions the following resources:

- Kubernetes pod (ephemeral)
- Kubernetes persistent volume claim (persistent on `/home/coder`)
- Claude Code AI assistant with task automation

This means, when the workspace restarts, any tools or files outside of the home directory are not persisted. To pre-bake tools into the workspace (e.g. `python3`), modify the container image. Alternatively, individual developers can [personalize](https://coder.com/docs/dotfiles) their workspaces with dotfiles.

## Features

- **VS Code Web**: Access VS Code through the browser
- **Kiro**: AI-powered code editor integration
- **Claude Code**: AI assistant for automated development tasks
- **Preview App**: Built-in preview server on port 3000
- **Configurable Resources**: Adjustable CPU, memory, and disk size

## Parameters

- **CPU**: Number of CPU cores (2 or 4)
- **Memory**: Amount of memory in GB (2 or 4)
- **Home Disk Size**: Size of persistent home directory in GB
- **AI Prompt**: Task prompt for Claude Code assistant

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.
