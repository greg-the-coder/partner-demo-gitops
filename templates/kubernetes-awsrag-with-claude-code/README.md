# AWS RAG Application Prototyping with Coder CDE

A Kubernetes-based Coder template that provides a complete development environment for AWS RAG (Retrieval-Augmented Generation) application prototyping with Claude Code integration.

## Architecture

This template creates:
- **Kubernetes workspace** with configurable CPU/memory resources
- **Aurora PostgreSQL Serverless v2** cluster with pgvector extension for vector storage
- **Claude Code integration** with AWS Bedrock for AI-assisted development
- **Pre-configured development environment** with AWS CLI, CDK, and Python tooling

## Key Components

### Infrastructure (`main.tf`)
- Kubernetes deployment with Coder agent
- Configurable compute resources (2-8 CPU cores, 2-8GB RAM)
- Git repository cloning (defaults to aws-rag-prototyping repo)
- Code-server and Claude Code modules
- Streamlit app preview on port 8501

### Database (`aws-aurora/aurora-pgvector.tf`)
- Aurora PostgreSQL 16.6 Serverless v2 cluster
- pgvector extension for vector embeddings
- Configurable scaling (0.5-1.0 ACU)
- Security group allowing PostgreSQL access

## Environment Variables

```bash
CLAUDE_CODE_USE_BEDROCK=1
ANTHROPIC_MODEL=us.anthropic.claude-3-7-sonnet-20250219-v1:0
PGVECTOR_HOST=<aurora-endpoint>
PGVECTOR_DATABASE=mydb1
PGVECTOR_USER=dbadmin
```

## Usage

1. Deploy template to Coder instance
2. Create workspace with desired CPU/memory configuration
3. Claude Code automatically sets up Python environment and installs dependencies
4. Access Streamlit preview at the provided URL
5. Use integrated development tools for RAG application prototyping

## Prerequisites

- Kubernetes cluster with Coder deployment
- AWS VPC with private subnets
- Appropriate IAM permissions for Aurora and Bedrock services