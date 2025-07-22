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

# Reference existing VPC
data "aws_vpc" "existing_vpc" {
  id = var.vpc_id
}

# Reference existing private subnets
data "aws_subnet" "existing_private_subnets" {
  count = length(var.subnet_ids)
  id    = var.subnet_ids[count.index]
}

# Create a subnet group for Aurora instances using existing subnets
resource "aws_db_subnet_group" "gtc_awsrag_aurora_subnet_group" {
  name       = "gtc_awsrag_aurora-subnet-group"
  subnet_ids = data.aws_subnet.existing_private_subnets[*].id

  tags = {
    Name = "gtc_awsrag Aurora Subnet Group"
  }
}

# Create security group for Aurora instances
resource "aws_security_group" "gtc_awsrag_aurora_sg" {
  name        = "gtc_awsrag_aurora-security-group"
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
  cluster_identifier      = "gtc-awsrag-aurora-postgres-1"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "16.6"
  database_name           = "mydb1"
  master_username         = "dbadmin"
  master_password         = "YourStrongPasswordHere1"  # Use AWS Secrets Manager in production
  db_subnet_group_name    = aws_db_subnet_group.gtc_awsrag_aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.gtc_awsrag_aurora_sg.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.pgvector_param_group.name
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
  identifier           = "gtc-awsrag-aurora-primary"
}

# Null resource to create pgvector extension after cluster creation
resource "null_resource" "create_pgvector_extension" {
  depends_on = [aws_rds_cluster_instance.gtc_awsrag_aurora_primary]

  provisioner "local-exec" {
    command = <<-EOT
      PGPASSWORD="YourStrongPasswordHere1" psql -h ${aws_rds_cluster.gtc_awsrag_aurora_postgres_1.endpoint} -U dbadmin -d mydb1 -c "CREATE EXTENSION IF NOT EXISTS vector;"
    EOT
  }
}

# Outputs
output "aurora_postgres_1_endpoint" {
  value = aws_rds_cluster.gtc_awsrag_aurora_postgres_1.endpoint
}

output "aurora_postgres_1_reader_endpoint" {
  value = aws_rds_cluster.gtc_awsrag_aurora_postgres_1.reader_endpoint
}
