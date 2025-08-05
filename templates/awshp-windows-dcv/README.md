---
display_name: AWS EC2 (Windows with DCV)
description: Provision AWS EC2 Windows VMs with NICE DCV as Coder workspaces
icon: ../../../site/static/icon/aws.svg
maintainer_github: coder
verified: true
tags: [vm, windows, aws, dcv, persistent-vm]
---

# Remote Development on AWS EC2 VMs (Windows with DCV)

Provision AWS EC2 Windows VMs with NICE DCV remote desktop as [Coder workspaces](https://coder.com/docs/workspaces) with this example template.

<!-- TODO: Add screenshot -->

## Prerequisites

### Authentication

By default, this template authenticates to AWS using the provider's default [authentication methods](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

The simplest way (without making changes to the template) is via environment variables (e.g. `AWS_ACCESS_KEY_ID`) or a [credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-format). If you are running Coder on a VM, this file must be in `/home/coder/aws/credentials`.

To use another [authentication method](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication), edit the template.

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
- NICE DCV remote desktop server
- VS Code integration for Windows

Coder uses `aws_ec2_instance_state` to start and stop the VM. This example template is fully persistent, meaning the full filesystem is preserved when the workspace restarts.

## Features

- **NICE DCV**: High-performance remote desktop access to Windows workspaces
- **VS Code on Windows**: Integrated VS Code experience
- **Configurable Resources**: Choose instance type and disk size
- **Multi-Region Support**: Deploy in various AWS regions

## Parameters

- **Region**: AWS region for deployment
- **Instance Type**: EC2 instance type (m5a.large or m5dn.xlarge)
- **Home Disk Size**: Root volume size in GB (50-300 GB)

## NICE DCV Access

NICE DCV provides high-performance remote desktop access to your Windows workspace. Connection details including username, password, and port forwarding instructions are available in the workspace metadata.

To connect:
1. Run `coder port-forward <workspace-name> -p <dcv-port>`
2. Connect to `localhost:<dcv-port><web-url-path>` in your browser
3. Use the provided username and password

> **Note**
> This template is designed to be a starting point! Edit the Terraform to extend the template to support your use case.