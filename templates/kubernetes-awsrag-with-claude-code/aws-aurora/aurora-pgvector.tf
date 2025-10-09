# variables for Coder Workspace Reference
variable "workspace_name" {
  type = string
  default = "awsragproto"
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "coder-aws-cluster"
}

# Variables for existing VPC and subnets
variable "vpc_id" {
  description = "ID of the existing VPC where Aurora will be deployed"
  type        = string
  default     = "vpc-0871232cd21251540"  # Replace with your actual VPC ID
}

variable "subnet_ids" {
  description = "List of subnet IDs where Aurora will be deployed"
  type        = list(string)
  default     = ["subnet-0f0535010fd77a0c3", "subnet-00cbe04ad50f37808", "subnet-0bdc79d34b7380f1b"]  # Replace with your actual subnet IDs
}
#Variables for Aurora PostgreSQL Serverless v2

variable "database_name" {
  description = "Name of the database to be created"
  type        = string
  default     = "mydb"
}
variable "db_master_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}
variable "db_master_password" {
  description = "Master password for the database"
  type        = string
  default     = "YourStrongPasswordHere1"  # Consider using AWS Secrets Manager for production
}

## Reference existing VPC
#data "aws_vpc" "existing_vpc" {
#  id = var.vpc_id
#}

## Reference existing private subnets
#data "aws_subnet" "existing_private_subnets" {
#  count = length(var.subnet_ids)
#  id    = var.subnet_ids[count.index]
#}

# Get EKS cluster info
data "aws_eks_cluster" "current" {
  name = var.eks_cluster_name  # Add this variable
}

# Use EKS VPC
data "aws_vpc" "existing_vpc" {
  id = data.aws_eks_cluster.current.vpc_config[0].vpc_id
}

# Get private subnets from EKS
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing_vpc.id]
  }
  
  tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Create a subnet group for Aurora instances using existing subnets
resource "aws_db_subnet_group" "gtc_awsrag_aurora_subnet_group" {
  name       = "${var.workspace_name}-sgrp"
  subnet_ids = data.aws_subnets.private.ids

  tags = {
    Name = "${var.workspace_name}-sgrp"
  }
}

# Create security group for Aurora instances
resource "aws_security_group" "gtc_awsrag_aurora_sg" {
  name        = "${var.workspace_name}-sg"
  description = "Security group for Aurora PostgreSQL instances"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow public access not restricted to the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gtc_awsrag_aurora-sg"
  }
}

# First Aurora PostgreSQL Serverless v2 instance
resource "aws_rds_cluster" "gtc_awsrag_aurora_postgres_1" {
  cluster_identifier      = "${var.workspace_name}-pgvector01"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "16.6"
  database_name           = var.database_name
  master_username         = var.db_master_username
  master_password         = var.db_master_password  # Use AWS Secrets Manager in production
  db_subnet_group_name    = aws_db_subnet_group.gtc_awsrag_aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.gtc_awsrag_aurora_sg.id]
  skip_final_snapshot     = true
  
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 1.0
  }
}

# Primary DB instance for the Aurora PostgreSQL cluster
resource "aws_rds_cluster_instance" "gtc_awsrag_aurora_primary" {
  cluster_identifier   = aws_rds_cluster.gtc_awsrag_aurora_postgres_1.id
  instance_class       = "db.serverless"
  engine               = "aurora-postgresql"
  engine_version       = "16.6"
  db_subnet_group_name = aws_db_subnet_group.gtc_awsrag_aurora_subnet_group.name
  identifier           = "${var.workspace_name}-primary"
}

# Outputs
output "aurora_postgres_1_endpoint" {
  value = aws_rds_cluster.gtc_awsrag_aurora_postgres_1.endpoint
}

output "aurora_postgres_1_reader_endpoint" {
  value = aws_rds_cluster.gtc_awsrag_aurora_postgres_1.reader_endpoint
}
