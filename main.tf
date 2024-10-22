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
  count             = 2
  vpc_id            = aws_vpc.diagram.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "diagram-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.diagram.id
  cidr_block = "10.0.3.0/24"
  tags = {
    Name = "diagram-private-subnet"
  }
}

resource "aws_nat_gateway" "diagram" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "diagram-natgw"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "diagram-eip"
  }
}

resource "aws_lb" "diagram" {
  name               = "diagram-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  tags = {
    Name = "diagram-alb"
  }
}

resource "aws_security_group" "alb" {
  name        = "diagram-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.diagram.id
  tags = {
    Name = "diagram-alb-sg"
  }
}

resource "aws_instance" "diagram" {
  ami                    = "ami-03f584e50b2d32776" # AL2023
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = "hiyama-diagram"
  associate_public_ip_address = true
  tags = {
    Name = "diagram-ec2"
  }
}

resource "aws_security_group" "ec2" {
  name        = "diagram-ec2-sg"
  description = "Security group for EC2"
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
  name = "diagram-flow-logs"
  tags = {
    Name = "diagram-flow-logs"
  }
}

resource "aws_sns_topic" "diagram" {
  name = "diagram