variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

resource "aws_vpc" "deploy" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "deploy-vpc"
  }
}

resource "aws_internet_gateway" "deploy" {
  vpc_id = aws_vpc.deploy.id

  tags = {
    Name = "deploy-igw"
  }
}

resource "aws_subnet" "deploy" {
  vpc_id            = aws_vpc.deploy.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "deploy-subnet"
  }
}

resource "aws_route_table" "deploy" {
  vpc_id = aws_vpc.deploy.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.deploy.id
  }

  tags = {
    Name = "deploy-rtb"
  }
}

resource "aws_route_table_association" "deploy" {
  subnet_id      = aws_subnet.deploy.id
  route_table_id = aws_route_table.deploy.id
}

resource "aws_security_group" "deploy" {
  name   = "deploy-sg"
  vpc_id = aws_vpc.deploy.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 適宜変更
  }

  tags = {
    Name = "deploy-sg"
  }
}

resource "aws_instance" "deploy" {
  ami           = "ami-03f584e50b2d32776" # AL2023
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.deploy.id
  key_name      = "hiyama-diagram"

  associate_public_ip_address = true
  vpc_security_group_ids     = [aws_security_group.deploy.id]

  tags = {
    Name = "deploy-ec2"
  }
}

resource "aws_s3_bucket" "deploy" {
  bucket = "deploy-bucket"

  tags = {
    Name = "deploy-s3"
  }
}