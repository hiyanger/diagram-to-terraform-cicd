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

resource "aws_vpc" "diagram" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "diagram-vpc"
  }
}

resource "aws_internet_gateway" "diagram" {
  vpc_id = aws_vpc.diagram.id
  tags = {
    Name = "diagram-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.diagram.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "diagram-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.diagram.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "diagram-private-subnet"
  }
}

resource "aws_nat_gateway" "diagram" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "diagram-nat-gateway"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "diagram-nat-eip"
  }
}

resource "aws_lb" "diagram" {
  name               = "diagram-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public.id]
  tags = {
    Name = "diagram-alb"
  }
}

resource "aws_instance" "diagram" {
  ami           = "ami-03f584e50b2d32776" # AL2023
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private.id
  key_name      = "hiyama-diagram"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.ec2.id]
  tags = {
    Name = "diagram-ec2"
  }
}

resource "aws_security_group" "ec2" {
  name        = "diagram-ec2-sg"
  description = "Security group for EC2 instance"
  vpc_id      = aws_vpc.diagram.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 適宜変更
  }

  tags = {
    Name = "diagram-ec2-sg"
  }
}

resource "aws_s3_bucket" "diagram" {
  bucket = "diagram-s3-bucket"
  tags = {
    Name = "diagram-s3"
  }
}

resource "aws_cloudwatch_log_group" "diagram" {
  name = "diagram-cloudwatch-log-group"
  tags = {
    Name = "diagram-cloudwatch"
  }
}

resource "aws_sns_topic" "diagram" {
  name = "diagram-sns-topic"
  tags = {
    Name = "diagram-sns"
  }
}

resource "aws_iam_role" "diagram" {
  name = "diagram-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags =