# Create a shared VPC for multiple Aurora instances
resource "aws_vpc" "gtc_awsrag_shared_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "gtc_awsrag_shared_vpc"
  }
}

# Create subnets across multiple availability zones
resource "aws_subnet" "gtc_awsrag_private_subnets" {
  count             = 3
  vpc_id            = aws_vpc.gtc_awsrag_shared_vpc.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = "us-east-1${["a", "b", "c"][count.index]}"

  tags = {
    Name = "gtc_awsrag_private-subnet-${count.index + 1}"
  }
}

# Create a subnet group for Aurora instances
resource "aws_db_subnet_group" "gtc_awsrag_aurora_subnet_group" {
  name       = "gtc_awsrag_aurora-subnet-group"
  subnet_ids = aws_subnet.gtc_awsrag_private_subnets[*].id

  tags = {
    Name = "gtc_awsrag Aurora Subnet Group"
  }
}

# Create security group for Aurora instances
resource "aws_security_group" "gtc_awsrag_aurora_sg" {
  name        = "gtc_awsrag_aurora-security-group"
  description = "Security group for Aurora PostgreSQL instances"
  vpc_id      = aws_vpc.gtc_awsrag_shared_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Allow access from within the VPC
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
  engine_version          = "13.9"
  database_name           = "mydb1"
  master_username         = "dbadmin"
  master_password         = "YourStrongPasswordHere1"  # Use AWS Secrets Manager in production
  db_subnet_group_name    = aws_db_subnet_group.gtc_awsrag_aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.gtc_awsrag_aurora_sg.id]
  skip_final_snapshot     = true
  
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 1.0
  }
}

# Outputs
output "aurora_postgres_1_endpoint" {
  value = aws_rds_cluster.gtc_awsrag_aurora_postgres_1.endpoint
}
