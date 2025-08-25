# AWS Coder Workshop Templates

This directory contains Coder workspace templates designed for AWS development workflows and workshop scenarios. Each template provides a specialized development environment with pre-configured tools and services.

## Template Overview

### 🐧 [AWS Workshop - EC2 (Linux) Q Developer](awshp-linux-q-base/)
**Purpose**: AI-powered development with Amazon Q Developer  
**Architecture**: Ubuntu 20.04 on x86_64 EC2 instances  
**Key Tools**: Amazon Q Developer CLI, AWS CLI v2, AWS CDK, Node.js 20 LTS  
**Best For**: AI-assisted development, infrastructure as code, general AWS development

### 🚀 [AWS Workshop - EC2 (Linux) SAM](awshp-linux-sam/)
**Purpose**: Serverless application development  
**Architecture**: Ubuntu ARM64 on Graviton EC2 instances  
**Key Tools**: AWS SAM CLI, AWS CLI v2, Python 3, Amazon Q Developer extension  
**Best For**: Lambda functions, serverless APIs, cost-effective ARM64 development

### 🪟 [AWS Workshop - EC2 (Windows) DCV](awshp-windows-dcv/)
**Purpose**: Windows development with remote desktop  
**Architecture**: Windows Server 2022 on x86_64 EC2 instances  
**Key Tools**: NICE DCV, VS Code, PowerShell, Windows development stack  
**Best For**: Windows-specific development, GUI applications, .NET development

### ☸️ [Kubernetes with Claude Code](awshp-k8s-with-claude-code/)
**Purpose**: Container development with AI task automation  
**Architecture**: Kubernetes pods with persistent volumes  
**Key Tools**: Claude Code AI assistant, VS Code, Cursor, container tools  
**Best For**: Microservices, container orchestration, AI-driven task automation

## Template Comparison

| Feature | Linux Q Developer | Linux SAM | Windows DCV | K8s Claude Code |
|---------|------------------|-----------|-------------|-----------------|
| **Platform** | Ubuntu x86_64 | Ubuntu ARM64 | Windows Server | Kubernetes |
| **AI Assistant** | Q Developer CLI | Q Developer Extension | - | Claude Code |
| **Primary Use** | General AWS Dev | Serverless | Windows Dev | Container Dev |
| **Cost Efficiency** | Standard | High (ARM64) | Higher | Variable |
| **Persistence** | Full VM | Full VM | Full VM | Home directory |
| **Startup Time** | ~2-3 min | ~2-3 min | ~5-10 min | ~30-60 sec |

## Getting Started

### Prerequisites
- Coder deployment with AWS provider configured
- AWS account with appropriate IAM permissions
- For Kubernetes template: Existing Kubernetes cluster

### Template Selection Guide

**Choose Linux Q Developer if you want:**
- AI-powered development assistance
- Infrastructure as Code with CDK
- General-purpose AWS development
- x86_64 compatibility requirements

**Choose Linux SAM if you want:**
- Serverless application development
- Cost-effective ARM64 instances
- Lambda function development
- Local serverless testing

**Choose Windows DCV if you want:**
- Windows-specific development
- GUI application development
- .NET or Windows-only tools
- Remote desktop experience

**Choose Kubernetes Claude Code if you want:**
- Container-based development
- AI task automation
- Microservices architecture
- Fast workspace startup times

## Configuration

### IAM Instance Profile
Most templates require an IAM instance profile for AWS service access. Configure the `aws_iam_profile` variable when deploying templates.

### Regional Deployment
All templates support multi-region deployment with region-specific optimizations:
- **Linux Q Developer**: 10 regions globally
- **Linux SAM**: 4 US regions (ARM64 availability)
- **Windows DCV**: 15 regions globally
- **Kubernetes**: Depends on cluster location

### Resource Sizing
Each template offers configurable resource options:
- **CPU**: 1-4 vCPUs depending on template
- **Memory**: 1-16 GiB RAM options
- **Storage**: 10-300 GB persistent volumes

## Workshop Integration

These templates are designed for the AWS Modernization with Coder workshop and include:
- Pre-configured development environments
- Workshop-specific tooling and dependencies
- Optimized resource configurations
- Integration with workshop exercises

## Support and Customization

Each template is designed as a starting point and can be customized for specific use cases:
- Modify Terraform configurations for additional AWS services
- Extend startup scripts for custom tool installation
- Adjust resource parameters for performance requirements
- Add custom applications and integrations

> **Note**: These templates are designed for workshop and development use. For production deployments, review and adjust security configurations, resource limits, and access controls according to your organization's requirements.