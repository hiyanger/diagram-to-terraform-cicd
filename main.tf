provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "diagram" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "diagram-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.diagram.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "diagram-public-subnet"
  }
}

resource "aws_instance" "diagram" {
  ami           = "ami-06b21ccaeff8cd686" # AL2023
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  key_name      = "hiyama-diagram"
  vpc_security_group_ids = [aws_security_group.diagram.id]
  tags = {
    Name = "diagram-ec2"
  }
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