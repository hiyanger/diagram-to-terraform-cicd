provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "diagram" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "diagram-vpc"
  }
}

resource "aws_subnet" "diagram" {
  vpc_id     = aws_vpc.diagram.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "diagram-subnet"
  }
}

resource "aws_internet_gateway" "diagram" {
  vpc_id = aws_vpc.diagram.id

  tags = {
    Name = "diagram-igw"
  }
}

resource "aws_route_table" "diagram" {
  vpc_id = aws_vpc.diagram.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.diagram.id
  }

  tags = {
    Name = "diagram-rt"
  }
}

resource "aws_route_table_association" "diagram" {
  subnet_id      = aws_subnet.diagram.id
  route_table_id = aws_route_table.diagram.id
}

resource "aws_security_group" "diagram" {
  name        = "diagram-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.diagram.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "diagram-sg"
  }
}

resource "aws_instance" "diagram" {
  ami           = "ami-06b21ccaeff8cd686"  # AL2023
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.diagram.id
  vpc_security_group_ids = [aws_security_group.diagram.id]
  key_name      = "hiyama-diagram"

  tags = {
    Name = "diagram-ec2"
  }
}