provider "aws" {
  region = "us-east-1"
}

# Create a new VPC with DNS enabled
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"
  }
}

# Create an Internet Gateway for public access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

# Create a Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Create two public subnets
resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Associate subnets with the Public Route Table
resource "aws_route_table_association" "subnet1_association" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "subnet2_association" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

# Create an RDS subnet group
resource "aws_db_subnet_group" "db_subnet" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

# Security Group: Allow public access 
resource "aws_security_group" "db_sg" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "rds-postgres-sg"
  description = "Allow PostgreSQL access from anywhere"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_db_instance" "master" {
  identifier              = "postgres-master"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "mydatabase"
  username               = "postgres"
  password               = ""
  publicly_accessible     = true
  backup_retention_period = 7  
  apply_immediately       = true  
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  skip_final_snapshot     = true
}


resource "aws_db_instance" "slave1" {
  identifier              = "postgres-slave1"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  replicate_source_db     = aws_db_instance.master.arn  
  publicly_accessible     = true
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  skip_final_snapshot     = true

  depends_on = [aws_db_instance.master] 
}

resource "aws_db_instance" "slave2" {
  identifier              = "postgres-slave2"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  replicate_source_db     = aws_db_instance.master.arn  
  publicly_accessible     = true
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  skip_final_snapshot     = true

  depends_on = [aws_db_instance.master]  
}

# Output database endpoints
output "master_endpoint" {
  value = aws_db_instance.master.endpoint
}

output "slave1_endpoint" {
  value = aws_db_instance.slave1.endpoint
}

output "slave2_endpoint" {
  value = aws_db_instance.slave2.endpoint
}

#psql -h postgres-master.dns -U postgres -d mydatabase

#psql -h postgres-slave1.dns -U postgres -d mydatabase

#psql -h postgres-slave2.dns -U postgres -d mydatabase