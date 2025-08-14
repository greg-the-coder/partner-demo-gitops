---
display_name: AWS Workshop - EC2 (Linux) SAM
description: Provision AWS EC2 VMs with AWS SAM CLI and serverless development tools as Coder workspaces
icon: ../../../site/static/icon/aws.svg
maintainer_github: coder
verified: true
tags: [vm, linux, aws, persistent-vm, sam, serverless, lambda]
---

# Remote Development on AWS EC2 VMs (Linux) with SAM

Provision AWS EC2 VMs with integrated AWS SAM CLI, AWS CLI, and Amazon Q Developer for serverless development as [Coder workspaces](https://coder.com/docs/workspaces) with this workshop template.

<!-- TODO: Add screenshot -->

## Prerequisites

### Infrastructure

**AWS Account**: This template requires an AWS account with appropriate permissions for EC2 and serverless service management

**IAM Instance Profile**: This template uses a configurable IAM instance profile for AWS service access

**Amazon Machine Image**: This template uses Ubuntu ARM64 AMI optimized for ARM-based EC2 instances

### Authentication

This template authenticates to AWS using the provider's default [authentication methods](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

To use another [authentication method](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication), edit the template.

### AWS SAM Integration

This template includes AWS SAM CLI integration that provides:
- Serverless application development and testing
- Local Lambda function execution
- API Gateway local development
- CloudFormation template management

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

- AWS EC2 Instance (Ubuntu ARM64)
- IAM instance profile for AWS service access
- Persistent EBS root volume
- ARM64-optimized development environment

Coder uses `aws_ec2_instance_state` to start and stop the VM. This template is fully persistent, meaning the full filesystem is preserved when the workspace restarts.

## Features

- **VS Code Web**: Access VS Code through the browser with Amazon Q Developer extension
- **AWS SAM CLI**: Serverless Application Model for Lambda development
- **AWS CLI**: Pre-installed ARM64 version for full AWS service support
- **Python 3**: Runtime environment for Lambda functions
- **ARM64 Optimization**: Graviton-based instances for cost-effective performance
- **Real-time Monitoring**: CPU, memory, and disk usage metrics

## Parameters

- **Region**: AWS region for deployment (4 US regions available)
- **Instance Type**: ARM64 EC2 instance type (m7g.medium or m7g.large)
- **Disk Size**: EBS root volume size (10, 20, or 40 GB options)
- **AWS IAM Profile**: IAM instance profile for AWS service access

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.

## Development Tools

### Code Server
`code-server` is installed directly and provides VS Code access through the browser on port 13337 with Amazon Q Developer extension pre-installed.

### AWS SAM CLI
The SAM CLI is automatically installed and provides:
- `sam init` for creating new serverless applications
- `sam build` for building serverless applications
- `sam local start-api` for local API Gateway testing
- `sam deploy` for deploying to AWS

### AWS Development Stack
- **AWS CLI v2**: ARM64-optimized version with full AWS service support
- **Python 3**: Runtime for Lambda function development
- **pip**: Package manager for Python dependencies

## Getting Started

1. Create a workspace using this template
2. Access VS Code through the Coder dashboard
3. Initialize a new SAM application with `sam init`
4. Develop and test Lambda functions locally
5. Deploy to AWS with `sam deploy`
