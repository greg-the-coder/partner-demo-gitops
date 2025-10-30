---
display_name: Universal Workspace Template on K8s
description: Demonstrates "all things possible" in Coder Workspaces
icon: ../../../site/static/icon/code.png
maintainer_github: coder
verified: true
tags: [kubernetes, container]
---

# Remote Development on K8s

> [!IMPORTANT]
> This template is centrally managed by CI/CD in the coder/templates repository.

Provision Kubernetes Deployments as [Coder workspaces](https://coder.com/docs/v2/latest/workspaces) with this template.

## Prerequisites

### Infrastructure

**Cluster**: This template requires an existing Kubernetes cluster

**Container Image**: This template uses the [codercom/enterprise-base:ubuntu image](https://github.com/coder/enterprise-images/tree/main/images/base) with some dev tools preinstalled. To add additional tools, extend this image or build it yourself.

### Authentication

This template authenticates using a `~/.kube/config`, if present on the server, or via built-in authentication if the Coder provisioner is running on Kubernetes with an authorized ServiceAccount. To use another [authentication method](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#authentication), edit the template.

## Architecture

This template provisions the following resources:

- Kubernetes pod (ephemeral)
- Kubernetes persistent volume claim (persistent on `/home/coder`)

This means, when the workspace restarts, any tools or files outside of the home directory are not persisted. To pre-bake tools into the workspace (e.g. `python3`), modify the container image. Alternatively, individual developers can [personalize](https://coder.com/docs/v2/latest/dotfiles) their workspaces with dotfiles.

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.