---
display_name: AWS Workshop - EC2 (Windows) DCV
description: Provision AWS EC2 Windows VMs with NICE DCV remote desktop and VS Code integration as Coder workspaces
icon: ../../../site/static/icon/aws.svg
maintainer_github: coder
verified: true
tags: [vm, windows, aws, dcv, persistent-vm, remote-desktop]
---

# Remote Development on AWS EC2 VMs (Windows) with DCV

Provision AWS EC2 Windows VMs with integrated NICE DCV remote desktop and VS Code as [Coder workspaces](https://coder.com/docs/workspaces) with this workshop template.

<!-- TODO: Add screenshot -->

## Prerequisites

### Infrastructure

**AWS Account**: This template requires an AWS account with appropriate permissions for EC2 instance management

**Amazon Machine Image**: This template uses Windows Server 2022 AMI from Amazon

### Authentication

This template authenticates to AWS using the provider's default [authentication methods](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

To use another [authentication method](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication), edit the template.

### NICE DCV Integration

This template includes NICE DCV integration that provides:
- High-performance remote desktop access to Windows workspaces
- Hardware-accelerated graphics and video streaming
- Multi-monitor support and USB redirection
- Secure encrypted connections

## Required permissions / policy

The following sample policy allows Coder to create EC2 instances and modify instances provisioned by Coder:

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

- AWS EC2 Windows Instance (Windows Server 2022)
- NICE DCV remote desktop server with web access
- VS Code integration module for Windows
- Persistent EBS root volume

Coder uses `aws_ec2_instance_state` to start and stop the VM. This template is fully persistent, meaning the full filesystem is preserved when the workspace restarts.

## Features

- **NICE DCV**: High-performance remote desktop access with web browser support
- **VS Code on Windows**: Integrated VS Code experience through custom module
- **Windows Server 2022**: Latest Windows Server with full development capabilities
- **Multi-Region Support**: Deploy across 15 AWS regions globally
- **Configurable Resources**: Choose instance type and disk size
- **Real-time Monitoring**: Instance metadata and connection details

## Parameters

- **Region**: AWS region for deployment (15 regions available globally)
- **Instance Type**: EC2 instance type (m5a.large or m5dn.xlarge)
- **Home Disk Size**: Root volume size in GB (50-300 GB range)

## NICE DCV Access

NICE DCV provides high-performance remote desktop access to your Windows workspace through a web browser. Connection details including username, password, and port forwarding instructions are available in the workspace metadata.

### Connection Steps
1. **Port Forward**: Run `coder port-forward <workspace-name> -p <dcv-port>`
2. **Web Access**: Connect to `localhost:<dcv-port><web-url-path>` in your browser
3. **Authentication**: Use the provided username and password from workspace metadata

### DCV Features
- **Web Browser Access**: No client installation required
- **Hardware Acceleration**: GPU-accelerated graphics when available
- **Multi-Monitor Support**: Full desktop experience
- **File Transfer**: Drag and drop file support
- **Clipboard Sync**: Copy/paste between local and remote systems

## Development Environment

### VS Code Integration
The template includes a custom VS Code module that provides seamless integration with the Windows environment.

### Windows Development Stack
- **Windows Server 2022**: Latest Windows Server with development tools
- **PowerShell**: Advanced scripting and automation capabilities
- **Windows Subsystem for Linux**: Optional Linux compatibility layer

## Getting Started

1. Create a workspace using this template
2. Wait for the instance to fully initialize (may take 5-10 minutes)
3. Use port forwarding to access DCV web interface
4. Connect through your browser using provided credentials
5. Access VS Code and other development tools through the Windows desktop

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.