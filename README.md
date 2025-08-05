# AWS Coder Workshop GitOps

AWS Workshop Demo of GitOps flow for Coder Template Admin

## Overview
A demonstration project showcasing GitOps workflows and best practices for Coder administration. This repo is meant to be used in conjunction with our [Kubernetes Devcontainer template](https://registry.coder.com/templates/kubernetes-devcontainer), which creates a Coder Workspace a Coder Admin can use for deployment and template administration.  The [.devcontainer specification](./.devcontainer/) contained in this repo will deploy a Workspace that has terraform, helm, and kubectl utilities provisioned that are commonly used by Platform Engineering teams supporting Coder. 

IaC is provided as terraform scripts along with bash script [templates_gitops.sh](./templates/templates_gitops.sh) that enable Coder templates to be created and versioned within this repo using a terraform-based GitOps flow.

## Prerequisites
- Coder 2.X deployment on K8S
- Coder Admin User access
- [Kubernetes Devcontainer template](https://registry.coder.com/templates/kubernetes-devcontainer) installed

## Setup Instructions
1. Fork or copy this repo into your own Git account
2. Create a Workspace from the Kubernetes Devcontainer template
3. Use the repo you forked/copied for the Repository parameter of the created Workspace

## GitOps Workflow
The GitOps workflow implemented in this demo uses terraform IaC, the Coder CLI, and a supplied bash script:
- [template_versions.tf](./templates/template_versions.tf) - Coder Template resource definitions
- [templates/..](./templates/) - Subdirectory for Coder Template IaC source code referenced in template_versions.tf
- From Coder Workspace, open a terminal and cd to [templates](./templates/)
- Initialize your Workspace terraform environment
```bash
terraform init
``` 
- Use the Coder CLI, and login into Coder and obtain Coder Session Token
```bash
coder login $CODER_AGENT_URL
```
- Create and update templates defined in template_versions.tf 
```bash
./templates_gitops.sh <Coder Session Token>
```

## Features
- Demonstrates Coder Kubernetes Devcontainer Workspaces for Platform Engineering
- Implements basic GitOps workflow for Coder Template adminstration using Coder CLI, Terraform, and Git for template change management 
- Other template source available at the [Coder Template Registry](https://registry.coder.com/templates)

