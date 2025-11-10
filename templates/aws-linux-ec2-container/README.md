---
display_name: AWS EC2 (Linux) with Container Development
description: Provision AWS EC2 VMs with Docker and devcontainer support for containerized development
icon: ../../../site/static/icon/aws.svg
maintainer_github: coder
verified: true
tags: [vm, linux, aws, persistent-vm, docker, devcontainer, containers]
---

# Container Development on AWS EC2 VMs (Linux)

Provision AWS EC2 VMs as [Coder workspaces](https://coder.com/docs/workspaces) with full container development support, including Docker and automatic devcontainer detection.

## Prerequisites

### Authentication

By default, this template authenticates to AWS using the provider's default [authentication methods](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

The simplest way (without making changes to the template) is via environment variables (e.g. `AWS_ACCESS_KEY_ID`) or a [credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-format). If you are running Coder on a VM, this file must be in `/home/coder/aws/credentials`.

To use another [authentication method](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication), edit the template.

## Required permissions / policy

The following sample policy allows Coder to create EC2 instances and modify
instances provisioned by Coder:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"ec2:GetDefaultCreditSpecification",
				"ec2:DescribeIamInstanceProfileAssociations",
				"ec2:DescribeTags",
				"ec2:DescribeInstances",
				"ec2:DescribeInstanceTypes",
				"ec2:DescribeInstanceStatus",
				"ec2:CreateTags",
				"ec2:RunInstances",
				"ec2:DescribeInstanceCreditSpecifications",
				"ec2:DescribeImages",
				"ec2:ModifyDefaultCreditSpecification",
				"ec2:DescribeVolumes"
			],
			"Resource": "*"
		},
		{
			"Sid": "CoderResources",
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeInstanceAttribute",
				"ec2:UnmonitorInstances",
				"ec2:TerminateInstances",
				"ec2:StartInstances",
				"ec2:StopInstances",
				"ec2:DeleteTags",
				"ec2:MonitorInstances",
				"ec2:CreateTags",
				"ec2:RunInstances",
				"ec2:ModifyInstanceAttribute",
				"ec2:ModifyInstanceCreditSpecification"
			],
			"Resource": "arn:aws:ec2:*:*:instance/*",
			"Condition": {
				"StringEquals": {
					"aws:ResourceTag/Coder_Provisioned": "true"
				}
			}
		}
	]
}
```

## Features

- **Docker Support**: Pre-installed Docker Engine with the Coder user added to the docker group
- **Devcontainer Integration**: Automatic detection and startup of devcontainers from `.devcontainer/devcontainer.json`
- **Git Repository Cloning**: Configurable repository URL and branch for automatic project setup
- **Development Tools**: Node.js LTS, build tools, and Devcontainer CLI pre-installed
- **Persistent Storage**: Full filesystem persistence across workspace restarts

## Template Parameters

- **Repository URL**: Git repository containing your devcontainer configuration (default: https://github.com/coder/coder-devcontainer-demo)
- **Repository Branch**: Git branch to checkout (default: main)
- **Region**: AWS region for deployment
- **Instance Type**: EC2 instance size (t3.large, t3.xlarge, t3.2xlarge)
- **Disk Size**: Root volume size (20-80 GB, adjustable via slider)

## Architecture

This template provisions the following resources:

- **AWS EC2 Instance**: Ubuntu 20.04 LTS with Docker and development tools
- **Git Clone Module**: Automatically clones the specified repository
- **Devcontainer Resource**: Detects and starts devcontainers from the cloned repository

Coder uses `aws_ec2_instance_state` to start and stop the VM. This template is fully persistent, meaning the full filesystem and container state are preserved when the workspace restarts.

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.

## Container Development Workflow

1. **Repository Setup**: The template automatically clones your specified Git repository
2. **Devcontainer Detection**: The `coder_devcontainer` resource scans for `.devcontainer/devcontainer.json` in your project
3. **Automatic Startup**: If a devcontainer configuration is found, it's automatically built and started
4. **Development Environment**: Your containerized development environment is ready with all dependencies installed

## Getting Started

1. Create a workspace using this template
2. Specify your repository URL containing a `.devcontainer/devcontainer.json` file
3. The workspace will automatically:
   - Clone your repository
   - Build the devcontainer image
   - Start the development container
   - Mount your code into the container

## Devcontainer Support

This template supports the full [Development Containers specification](https://containers.dev/), including:
- Custom Docker images and Dockerfiles
- VS Code extensions and settings
- Port forwarding configuration
- Environment variables and secrets
- Post-creation commands and lifecycle scripts
