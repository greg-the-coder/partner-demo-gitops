---
display_name: AWS Workshop - EC2 (Linux) Q Developer
description: Provision AWS EC2 VMs with Amazon Q Developer CLI and AWS development tools as Coder workspaces
icon: ../../../site/static/icon/aws.svg
maintainer_github: coder
verified: true
tags: [vm, linux, aws, persistent-vm, q-developer, aws-cli, cdk]
---

# Remote Development on AWS EC2 VMs (Linux) with Q Developer

Provision AWS EC2 VMs with integrated Amazon Q Developer CLI, AWS CLI, and AWS CDK as [Coder workspaces](https://coder.com/docs/workspaces) with this workshop template.

## Prerequisites

### Infrastructure

**AWS Account**: This template requires an AWS account with appropriate permissions for EC2 instance management

**IAM Instance Profile**: This template uses a configurable IAM instance profile for AWS service access

### Authentication

This template authenticates to AWS using the provider's default [authentication methods](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

To use another [authentication method](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication), edit the template.

### Amazon Q Developer Integration

This template includes Amazon Q Developer CLI integration that provides:
- AI-powered code generation and assistance
- Natural language to code conversion
- AWS service integration and best practices
- Interactive development workflows

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

## Architecture

This template provisions the following resources:

- AWS EC2 Instance (Ubuntu 20.04 LTS)
- IAM instance profile for AWS service access
- Cloud-init configuration for automated setup
- Persistent EBS root volume

Coder uses `aws_ec2_instance_state` to start and stop the VM. This template is fully persistent, meaning the full filesystem is preserved when the workspace restarts.

## Features

- **VS Code Web**: Access VS Code through the browser via code-server
- **Amazon Q Developer CLI**: AI-powered development assistance
- **AWS CLI**: Pre-installed and configured AWS command line interface
- **AWS CDK**: Cloud Development Kit with Node.js runtime
- **Multi-Region Support**: Deploy in various AWS regions
- **Configurable Resources**: Choose instance type and disk size
- **Real-time Monitoring**: CPU, memory, and disk usage metrics

## Parameters

- **Region**: AWS region for deployment (10 regions available)
- **Instance Type**: EC2 instance type (t3.micro to t3.large)
- **Root Volume Size**: EBS root volume size in GB (minimum 1 GB, expandable)
- **AWS IAM Profile**: IAM instance profile for AWS service access

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.

## Development Tools

### Code Server
`code-server` is installed via the Coder registry module and provides VS Code access through the browser.

### Amazon Q Developer CLI
The Q Developer CLI is automatically installed and provides:
- Interactive chat sessions for development assistance
- Code generation and explanation capabilities
- AWS service integration guidance

### AWS Development Stack
- **AWS CLI v2**: Latest version with full AWS service support
- **AWS CDK**: Infrastructure as Code with TypeScript/JavaScript
- **Node.js 20 LTS**: Runtime for CDK and modern JavaScript development

## Getting Started

1. Create a workspace using this template
2. Access VS Code through the Coder dashboard
3. Initialize Q Developer CLI with `q login`
4. Start developing with AI assistance using `q chat`
